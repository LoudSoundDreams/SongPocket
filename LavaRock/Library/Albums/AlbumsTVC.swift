//
//  AlbumsTVC.swift
//  LavaRock
//
//  Created by h on 2020-04-28.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import CoreData

final class AlbumsTVC:
	LibraryTVC,
	NoItemsBackgroundManager,
	OrganizeAlbumsPreviewing
{
	enum Purpose {
		case organizingAlbums(OrganizeAlbumsClipboard)
		case movingAlbums(MoveAlbumsClipboard)
		case browsing
	}
	
	// MARK: - Properties
	
	// NoItemsBackgroundManager
	private(set) lazy var noItemsBackgroundView = tableView.dequeueReusableCell(withIdentifier: "No Albums Placeholder")
	
	// Controls
	private lazy var moveOrOrganizeButton = UIBarButtonItem(
		title: LocalizedString.move,
		menu: makeOrganizeOrMoveMenu())
	
	// Purpose
	var purpose: Purpose {
		if let clipboard = organizeAlbumsClipboard {
			return .organizingAlbums(clipboard)
		}
		if let clipboard = moveAlbumsClipboard {
			return .movingAlbums(clipboard)
		}
		return .browsing
	}
	
	// State
	var indexOfOpenedCollection: Int? = nil
	var idsOfAlbumsToKeepSelected: Set<NSManagedObjectID> = []
	
	// MARK: “Organize Albums” Sheet
	
	// Data
	var organizeAlbumsClipboard: OrganizeAlbumsClipboard? = nil
	
	// Controls
	private lazy var saveOrganizeButton = makeSaveOrganizeButton()
	
	// MARK: “Move Albums” Sheet
	
	// Data
	var moveAlbumsClipboard: MoveAlbumsClipboard? = nil
	
	// MARK: - Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		sortOptionsGrouped = [
			[.newestFirst, .oldestFirst],
			[.random, .reverse],
		]
	}
	
	final override func setUpUI() {
		// Choose our buttons for the navigation bar and toolbar before calling super, because super sets those buttons.
		switch purpose {
		case .organizingAlbums:
			topRightButtons = [cancelAndDismissButton]
			viewingModeToolbarButtons = [
				.flexibleSpace(),
				saveOrganizeButton,
				.flexibleSpace(),
			]
		case .movingAlbums:
			topRightButtons = [cancelAndDismissButton]
		case .browsing:
			break
		}
		
		super.setUpUI()
		
		if Enabling.multicollection {
			navigationItem.largeTitleDisplayMode = .never
		}
		
		switch purpose {
		case .organizingAlbums(let clipboard):
			navigationItem.prompt = clipboard.prompt
		case .movingAlbums(let clipboard):
			navigationItem.prompt = clipboard.prompt
			navigationController?.toolbar.isHidden = true
		case .browsing:
			editingModeToolbarButtons = [
				moveOrOrganizeButton, .flexibleSpace(),
				sortButton, .flexibleSpace(),
				floatToTopButton, .flexibleSpace(),
				sinkToBottomButton,
			]
		}
	}
	
	@IBAction private func unwindToAlbumsFromEmptyAlbum(_ unwindSegue: UIStoryboardSegue) {
	}
	
	/*
	final override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if let collectionIndex = indexOfOpenedCollection {
			indexOfOpenedCollection = nil
			let sectionToAppearAt = viewModel.numberOfPresections + collectionIndex
			let indexPathToAppearAt = IndexPath(row: 0, section: sectionToAppearAt)
			tableView.scrollToRow(at: indexPathToAppearAt, at: .top, animated: false)
//			print("")
//			print(tableView.adjustedContentInset)
//			print(tableView.contentOffset)
		}
	}
	*/
	
//	final override func scrollViewDidScroll(_ scrollView: UIScrollView) {
//		print("Scrolled.")
//		print(tableView.adjustedContentInset)
//		print(tableView.contentOffset)
//	}
	
	// MARK: - Freshening UI
	
	final override func reflectViewModelIsEmpty() {
		let toDelete = tableView.allSections()
		deleteThenExit(sections: toDelete)
	}
	
	final override func freshenEditingButtons() {
		super.freshenEditingButtons()
		
		moveOrOrganizeButton.isEnabled = allowsMoveOrOrganize()
	}
	
	private func allowsMoveOrOrganize() -> Bool {
		guard !viewModel.isEmpty() else {
			return false
		}
		if tableView.indexPathsForSelectedRowsNonNil.isEmpty {
			return viewModel.viewContainerIsSpecific()
		} else {
			return true
		}
	}
	
	// MARK: - Navigation
	
	final override func prepare(
		for segue: UIStoryboardSegue,
		sender: Any?
	) {
		let albumsViewModel = viewModel as! AlbumsViewModel
		
		guard
			let selectedIndexPath = tableView.indexPathForSelectedRow,
			let songsTVC = segue.destination as? SongsTVC
		else { return }
		
		if Enabling.multialbum {
			let album = albumsViewModel.albumNonNil(at: selectedIndexPath)
			songsTVC.openedAlbum = album
			
			songsTVC.viewModel = SongsViewModel(
				viewContainer: .library,
				context: viewModel.context)
		} else {
			let album = albumsViewModel.albumNonNil(at: selectedIndexPath)
			songsTVC.viewModel = SongsViewModel(
				viewContainer: .container(album),
				context: viewModel.context)
		}
	}
}
