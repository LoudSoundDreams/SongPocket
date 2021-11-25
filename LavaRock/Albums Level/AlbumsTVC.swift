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
	AlbumMover,
	NoItemsBackgroundManager
{
	
	// MARK: - Properties
	
	// NoItemsBackgroundManager
	lazy var noItemsBackgroundView = tableView.dequeueReusableCell(withIdentifier: "No Albums Placeholder")
	
	// Controls
	private lazy var moveOrOrganizeButton = UIBarButtonItem(
		title: LocalizedString.move,
		menu: moveOrOrganizeMenu())
	private lazy var moveButton: UIBarButtonItem = {
		let action = UIAction { _ in self.startMovingAlbums() }
		return UIBarButtonItem(
			title: LocalizedString.move,
			primaryAction: action)
	}()
	
	// State
	var indexOfOpenedCollection: Int? = nil
	
	// MARK: "Moving Albums" Mode
	
	// Controls
	private lazy var moveHereButton: UIBarButtonItem = {
		let action = UIAction { _ in self.moveAlbumsHere() }
		let button = UIBarButtonItem(
			title: LocalizedString.moveHere,
			primaryAction: action)
		button.style = .done
		return button
	}()
	
	var albumMoverClipboard: AlbumMoverClipboard?
	
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
		if albumMoverClipboard != nil {
			topRightButtons = [cancelMoveAlbumsButton]
			viewingModeToolbarButtons = [
				.flexibleSpace(),
				moveHereButton,
				.flexibleSpace(),
			]
		}
		
		super.setUpUI()
		
		if FeatureFlag.multicollection {
			navigationItem.largeTitleDisplayMode = .never
		}
		
		if let albumMoverClipboard = albumMoverClipboard {
			navigationItem.prompt = albumMoverClipboard.navigationItemPrompt
			
			tableView.allowsSelection = false
			
			if FeatureFlag.tabBar {
				showToolbar()
			}
		} else {
			editingModeToolbarButtons = [
//				moveOrOrganizeButton, .flexibleSpace(),
				
				
				moveButton, .flexibleSpace(),
				sortButton, .flexibleSpace(),
				floatToTopButton, .flexibleSpace(),
				sinkToBottomButton,
			]
		}
	}
	
	// MARK: Setup Events
	
	@IBAction private func unwindToAlbumsFromEmptyAlbum(_ unwindSegue: UIStoryboardSegue) {
	}
	
	final override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if let collectionIndex = indexOfOpenedCollection {
			indexOfOpenedCollection = nil
			let sectionToAppearAt = AlbumsViewModel.numberOfSectionsAboveLibraryItems + collectionIndex
			let indexPathToAppearAt = IndexPath(row: 0, section: sectionToAppearAt)
			tableView.scrollToRow(at: indexPathToAppearAt, at: .top, animated: false)
//			print("")
//			print(tableView.adjustedContentInset)
//			print(tableView.contentOffset)
		}
	}
	
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
		moveButton.isEnabled = allowsMove()
	}
	
	private func allowsMoveOrOrganize() -> Bool {
		guard !viewModel.isEmpty() else {
			return false
		}
		if tableView.indexPathsForSelectedRowsNonNil.isEmpty {
			return viewModel.viewContainerIsSpecific
		} else {
			return true
		}
	}
	
	private func allowsMove() -> Bool {
		return allowsMoveOrOrganize()
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
		
		let selectedCell = tableView.cellForRow(at: selectedIndexPath)
		if selectedCell is AlbumCell {
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
	
}
