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
	private lazy var moveOrOrganizeButton: UIBarButtonItem = {
		if #available(iOS 14, *) {
			return UIBarButtonItem(
				title: LocalizedString.move,
				menu: moveOrOrganizeMenu())
		} else { // iOS 13
			return UIBarButtonItem(
				title: LocalizedString.move,
				style: .plain,
				target: self,
				action: #selector(showMoveOrOrganizeActionSheet))
		}
	}()
	private lazy var organizeButton = UIBarButtonItem(
		title: "Organize", // TO DO: Localize
		style: .plain,
		target: self,
		action: #selector(startOrganizingAlbums))
	private lazy var moveButton = UIBarButtonItem(
		title: LocalizedString.move,
		style: .plain,
		target: self,
		action: #selector(startMovingAlbums))
	
	// MARK: "Moving Albums" Mode
	
	// "Constants"
	private lazy var moveHereButton = UIBarButtonItem(
		title: LocalizedString.moveHere,
		style: .done,
		target: self,
		action: #selector(moveAlbumsHere))
	
	// Variables
	var albumMoverClipboard: AlbumMoverClipboard?
	
	// MARK: - Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		entityName = "Album"
		sortOptionGroups = [
			[.newestFirst,
			 .oldestFirst],
			[.reverse]
		]
	}
	
	// MARK: Setting Up UI
	
	final override func setUpUI() {
		// Choose our buttons for the navigation bar and toolbar before calling super, because super sets those buttons.
		if albumMoverClipboard != nil {
			topRightButtons = [cancelMoveAlbumsButton]
			viewingModeToolbarButtons = [
				.flexibleSpac3(),
				moveHereButton,
				.flexibleSpac3(),
			]
		}
		
		super.setUpUI()
		
		if let albumMoverClipboard = albumMoverClipboard {
			navigationItem.prompt = albumMoverClipboard.navigationItemPrompt
			
			tableView.allowsSelection = false
		} else {
			editingModeToolbarButtons = [
//				moveOrOrganizeButton,
//				.flexibleSpac3(),
				
//				organizeButton,
//				.flexibleSpac3(),
				
				moveButton,
				.flexibleSpac3(),
				
				sortButton,
				.flexibleSpac3(),
				
//				moveToTopOrBottomButton,
				floatToTopButton,
				.flexibleSpac3(),
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
	
	final override func refreshBarButtons() {
		super.refreshBarButtons()
		
		if isEditing {
			moveOrOrganizeButton.isEnabled = allowsMoveOrOrganize()
			organizeButton.isEnabled = allowsOrganize()
			moveButton.isEnabled = allowsMove()
			
			
			print("Is Move button enabled? \(moveButton.isEnabled)")
		}
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
