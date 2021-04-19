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
	AlbumMover
{
	
	// MARK: - Properties
	
	// "Constants"
	lazy var startMovingAlbumsButton = UIBarButtonItem(
		title: LocalizedString.move,
		style: .plain, target: self, action: #selector(startMovingAlbums))
	
	// Variables
	var albumMoverClipboard: AlbumMoverClipboard?
	
	// MARK: - Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		entityName = "Album"
	}
	
	// MARK: Setting Up UI
	
	final override func setUpUI() {
		super.setUpUI()
		
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
			sortOptions = [.newestFirst, .oldestFirst]
		}
	}
	
	final override func refreshNavigationItemTitle() {
		guard let containingCollection = sectionOfLibraryItems.container as? Collection else { return }
		title = containingCollection.title
	}
	
	// MARK: Setup Events
	
	@IBAction func unwindToAlbumsFromEmptyAlbum(_ unwindSegue: UIStoryboardSegue) {
	}
	
	// MARK: - Refreshing Buttons
	
	// This is the same as in CollectionsTVC.
	final override func setToolbarButtons(animated: Bool) {
		if albumMoverClipboard != nil {
			return // Prevent LibraryTVC from changing the toolbar in the storyboard to the playback toolbar.
		}
		
		super.setToolbarButtons(animated: animated)
	}
	
	final override func refreshBarButtons() {
		super.refreshBarButtons()
		
		if isEditing {
			refreshStartMovingAlbumsButton()
		}
	}
	
	private func refreshStartMovingAlbumsButton() {
		startMovingAlbumsButton.isEnabled =
			!sectionOfLibraryItems.items.isEmpty
	}
	
}
