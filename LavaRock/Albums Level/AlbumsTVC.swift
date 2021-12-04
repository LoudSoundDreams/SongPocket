//
//  AlbumsTVC.swift
//  LavaRock
//
//  Created by h on 2020-04-28.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import CoreData
import MediaPlayer

final class AlbumsTVC:
	LibraryTVC,
	NoItemsBackgroundManager,
	AlbumOrganizer
{
	
	enum Purpose {
		case organizingAlbums(AlbumOrganizerClipboard)
		case movingAlbums(AlbumMoverClipboard)
		case browsing
	}
	
	// MARK: - Properties
	
	// NoItemsBackgroundManager
	lazy var noItemsBackgroundView = tableView.dequeueReusableCell(withIdentifier: "No Albums Placeholder")
	
	// Controls
	private lazy var moveOrOrganizeButton = UIBarButtonItem(
		title: LocalizedString.move,
		menu: makeOrganizeOrMoveMenu())
	
	// Purpose
	var purpose: Purpose {
		if let clipboard = albumOrganizerClipboard {
			return .organizingAlbums(clipboard)
		}
		if let clipboard = albumMoverClipboard {
			return .movingAlbums(clipboard)
		}
		return .browsing
	}
	
	// State
	var indexOfOpenedCollection: Int? = nil
	var idsOfAlbumsToKeepSelected: Set<NSManagedObjectID> = []
	
	// MARK: “Organize Albums” Sheet
	
	// Data
	var albumOrganizerClipboard: AlbumOrganizerClipboard? = nil
	
	// Controls
	private lazy var commitOrganizeButton = makeCommitOrganizeButton()
	
	// MARK: “Move Albums” Sheet
	
	// Data
	var albumMoverClipboard: AlbumMoverClipboard? = nil
	
	// Controls
	private lazy var moveHereButton: UIBarButtonItem = {
		let action = UIAction { _ in self.moveHere() }
		let button = UIBarButtonItem(
			title: LocalizedString.moveHere,
			primaryAction: action)
		button.style = .done
		return button
	}()
	
	// MARK: - Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		sortOptionsGrouped = [
			[.newestFirst, .oldestFirst],
			[.reverse],
		]
	}
	
	final override func setUpUI() {
		// Choose our buttons for the navigation bar and toolbar before calling super, because super sets those buttons.
		switch purpose {
		case .organizingAlbums:
			topRightButtons = [cancelAndDismissButton]
			viewingModeToolbarButtons = [
				.flexibleSpace(),
				commitOrganizeButton,
				.flexibleSpace(),
			]
		case .movingAlbums:
			topRightButtons = [cancelAndDismissButton]
			navigationController?.toolbar.isHidden = true
//			viewingModeToolbarButtons = [ // RB2DO: Delete this
//				.flexibleSpace(),
//				moveHereButton,
//				.flexibleSpace(),
//			]
		case .browsing:
			break
		}
		
		super.setUpUI()
		
		if FeatureFlag.multicollection {
			navigationItem.largeTitleDisplayMode = .never
		}
		
		switch purpose {
		case .organizingAlbums(let clipboard):
			navigationItem.prompt = clipboard.prompt
		case .movingAlbums(let clipboard):
			navigationItem.prompt = clipboard.prompt
			
			if FeatureFlag.tabBar {
				showToolbar()
			}
		case .browsing:
			editingModeToolbarButtons = [
				moveOrOrganizeButton, .flexibleSpace(),
				sortButton, .flexibleSpace(),
				floatToTopButton, .flexibleSpace(),
				sinkToBottomButton,
			]
		}
	}
	
	// MARK: Setup Events
	
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
	
	// MARK: - Refreshing UI
	
	final override func reflectViewModelIsEmpty() {
		let toDelete = tableView.allSections()
		deleteThenExit(sections: toDelete)
	}
	
	final override func refreshEditingButtons() {
		super.refreshEditingButtons()
		
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
		guard
			let selectedIndexPath = tableView.indexPathForSelectedRow,
			let songsTVC = segue.destination as? SongsTVC,
			let albumsViewModel = viewModel as? AlbumsViewModel
		else { return }
		
		if FeatureFlag.multialbum {
			let album = albumsViewModel.itemNonNil(at: selectedIndexPath) as! Album
			songsTVC.openedAlbum = album
			
			songsTVC.viewModel = SongsViewModel(
				viewContainer: .library,
				context: viewModel.context)
		} else {
			let album = albumsViewModel.itemNonNil(at: selectedIndexPath) as! Album
			songsTVC.viewModel = SongsViewModel(
				viewContainer: .container(album),
				context: viewModel.context)
		}
	}
	
}
