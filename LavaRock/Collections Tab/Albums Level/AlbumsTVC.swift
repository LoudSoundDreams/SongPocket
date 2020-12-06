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
	NavigationItemTitleCustomizer,
	AlbumMover
{
	
	// MARK: - Properties
	
	// "Constants"
	lazy var startMovingAlbumsButton = UIBarButtonItem(
		title: LocalizedString.move,
		style: .plain, target: self, action: #selector(startMovingAlbums))
	
	// Variables
	var albumMoverClipboard: AlbumMoverClipboard?
	var newCollectionDetector: MovedAlbumsToNewCollectionDetector?
	
	// MARK: - Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		coreDataEntityName = "Album"
	}
	
	// MARK: Setting Up UI
	
	override func setUpUI() {
		super.setUpUI()
		
		refreshNavigationItemTitle()
		
		if let albumMoverClipboard = albumMoverClipboard {
			navigationItem.prompt = albumMoverClipboard.navigationItemPrompt
			navigationItem.rightBarButtonItem = cancelMoveAlbumsButton
			
			tableView.allowsSelection = false
			
		} else {
			toolbarButtonsEditingModeOnly = [
				startMovingAlbumsButton,
				flexibleSpaceBarButtonItem,
				sortButton,
				flexibleSpaceBarButtonItem,
				floatToTopButton,
				flexibleSpaceBarButtonItem,
				sinkToBottomButton
			]
			sortOptions = ["Newest First", "Oldest First"]
		}
	}
	
	final func refreshNavigationItemTitle() {
		if let containingCollection = containerOfLibraryItems as? Collection {
			title = containingCollection.title
		}
	}
	
	// MARK: Setup Events
	
//	@IBAction func unwindToAlbumsAfterMovingAlbums(_ unwindSegue: UIStoryboardSegue) {
//		refreshDataAndViews() // Exits this Collection if it's now empty.
//	}
	
	@IBAction func unwindToAlbumsFromEmptyAlbum(_ unwindSegue: UIStoryboardSegue) {
	}
	
	// MARK: - Events
	
	override func setToolbarButtons(animated: Bool) {
		if albumMoverClipboard != nil { return } // In "moving Albums" mode, prevent LibraryTVC from changing the toolbar in the storyboard to the playback toolbar.
		
		super.setToolbarButtons(animated: animated)
	}
	
	override func refreshBarButtons() {
		super.refreshBarButtons()
		
		if isEditing {
			refreshStartMovingAlbumsButton()
		}
	}
	
	private func refreshStartMovingAlbumsButton() {
		startMovingAlbumsButton.isEnabled =
			indexedLibraryItems.count > 0// &&
//			tableView.indexPathsForSelectedRows != nil
//		if tableView.indexPathsForSelectedRows == nil {
//			startMovingAlbumsButton.title = "Move All"
//		} else {
//			startMovingAlbumsButton.title = "Move"
//		}
	}
	
	// MARK: - Navigation
	
//	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//		if
//			segue.identifier == "Moved Albums",
//			let nonmodalAlbumsTVC = segue.destination as? AlbumsTVC,
//			let newCollectionDetector = newCollectionDetector,
//			newCollectionDetector.shouldDetectNewCollectionsOnNextViewWillAppear
//		{
//			nonmodalAlbumsTVC.newCollectionDetector!.shouldDetectNewCollectionsOnNextViewWillAppear = true
//		}
//
//		super.prepare(for: segue, sender: sender)
//	}
	
}
