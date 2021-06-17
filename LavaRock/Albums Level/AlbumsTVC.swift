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
	private lazy var startMovingAlbumsButton = UIBarButtonItem(
		title: LocalizedString.move,
		style: .plain, target: self, action: #selector(startMovingAlbums))
	private lazy var moveAlbumsHereButton = UIBarButtonItem(
		title: LocalizedString.moveHere,
		style: .done, target: self, action: #selector(moveAlbumsHere))
	
	// Variables
	var albumMoverClipboard: AlbumMoverClipboard?
	
	// MARK: - Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		entityName = "Album"
	}
	
	// MARK: Setting Up UI
	
	final override func setUpUI() {
		// Choose our buttons for the navigation bar and toolbar before calling super, because super sets those buttons.
		if albumMoverClipboard != nil {
//			topRightButtons = [moveAlbumsHereButton]
//			navigationController?.toolbar.isHidden = true
			
			topRightButtons = [cancelMoveAlbumsButton]
			bottomButtonsInViewingMode = [
				.flexibleSpac3(),
				moveAlbumsHereButton,
				.flexibleSpac3(),
			]
		}
		
		super.setUpUI()
		
		if let albumMoverClipboard = albumMoverClipboard {
			navigationItem.prompt = albumMoverClipboard.navigationItemPrompt
			
			tableView.allowsSelection = false
			
		} else {
			bottomButtonsInEditingMode = [
				startMovingAlbumsButton,
				.flexibleSpac3(),
				sortButton,
				.flexibleSpac3(),
				floatToTopButton,
				.flexibleSpac3(),
				sinkToBottomButton,
			]
			sortOptions = [
				.newestFirst,
				.oldestFirst,
				.reverse,
			]
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
