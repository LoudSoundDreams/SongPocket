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
	private lazy var moveOrOrganizeButton = UIBarButtonItem(
		title: LocalizedString.move,
		menu: moveOrOrganizeMenu())
	private lazy var moveButton: UIBarButtonItem = {
		let action = UIAction { _ in self.startMovingAlbums() }
		return UIBarButtonItem(
			title: LocalizedString.move,
			primaryAction: action)
	}()
	
	// MARK: "Moving Albums" Mode
	
	// "Constants"
	private lazy var moveHereButton: UIBarButtonItem = {
		let action = UIAction { _ in self.moveAlbumsHere() }
		let button = UIBarButtonItem(
			title: LocalizedString.moveHere,
			primaryAction: action)
		button.style = .done
		return button
	}()
	
	// Variables
	var albumMoverClipboard: AlbumMoverClipboard?
	
	// MARK: - Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		entityName = "Album"
		sortOptionsGrouped = [
			[.newestFirst, .oldestFirst],
			[.reverse],
		]
	}
	
	// MARK: Setting Up UI
	
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
		
		if let albumMoverClipboard = albumMoverClipboard {
			navigationItem.prompt = albumMoverClipboard.navigationItemPrompt
			
			tableView.allowsSelection = false
		} else {
			editingModeToolbarButtons = [
//				moveOrOrganizeButton,
//				.flexibleSpace(),
				
				moveButton,
				.flexibleSpace(),
				
				sortButton,
				.flexibleSpace(),
				
				floatToTopButton,
				.flexibleSpace(),
				sinkToBottomButton,
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
	
	final override func refreshEditingButtons() {
		super.refreshEditingButtons()
		
		moveOrOrganizeButton.isEnabled = allowsMoveOrOrganize()
		moveButton.isEnabled = allowsMove()
	}
	
	// MARK: - Navigation
	
	final override func prepare(
		for segue: UIStoryboardSegue,
		sender: Any?
	) {
		if
			segue.identifier == "Drill Down in Library",
			let songsTVC = segue.destination as? SongsTVC,
			let selectedIndexPath = tableView.indexPathForSelectedRow
		{
			songsTVC.managedObjectContext = managedObjectContext
			let selectedItem = libraryItem(for: selectedIndexPath)
			songsTVC.sectionOfLibraryItems = SectionOfSongs(
				managedObjectContext: managedObjectContext,
				container: selectedItem)
			
			return
		}
		
		super.prepare(for: segue, sender: sender)
	}
	
}
