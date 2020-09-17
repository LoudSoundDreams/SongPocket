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
	@IBOutlet var startMovingAlbumsButton: UIBarButtonItem!
	
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
			
			setAlbumMoverToolbar()
			
		} else {
			navigationItemButtonsEditingModeOnly = [floatToTopButton, startMovingAlbumsButton]
		}
	}
	
	func refreshNavigationItemTitle() {
		if let containingCollection = containerOfData as? Collection {
			title = containingCollection.title
		}
	}
	
	func setAlbumMoverToolbar() {
		toolbarItems = [
			flexibleSpaceBarButtonItem,
			UIBarButtonItem(
				title: "Move Here",
				style: .plain,
				target: self,
				action: #selector(moveAlbumsHere)),
			flexibleSpaceBarButtonItem
		]
	}
	
	// MARK: Setup Events
	
	@IBAction func unwindToAlbumsAfterMovingAlbums(_ unwindSegue: UIStoryboardSegue) {
		refreshDataAndViews() // Exits this collection if it's now empty.
	}
	
	@IBAction func unwindToAlbumsFromEmptyAlbum(_ unwindSegue: UIStoryboardSegue) {
	}
	
	// MARK: - Events
	
	override func refreshBarsAndButtons() {
		super.refreshBarsAndButtons()
		
		if isEditing {
			refreshStartMovingAlbumsButton()
		}
	}
	
	private func refreshStartMovingAlbumsButton() {
		startMovingAlbumsButton.isEnabled = indexedLibraryItems.count > 0
		if tableView.indexPathsForSelectedRows == nil {
			startMovingAlbumsButton.title = "Move All"
		} else {
			startMovingAlbumsButton.title = "Move"
		}
	}
	
	override func setRefreshedToolbar() {
		if albumMoverClipboard != nil {
		} else {
			super.setRefreshedToolbar()
		}
	}
	
	// MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if
			segue.identifier == "Moved Albums",
			let nonmodalAlbumsTVC = segue.destination as? AlbumsTVC,
			let newCollectionDetector = newCollectionDetector,
			newCollectionDetector.shouldDetectNewCollectionsOnNextViewWillAppear
		{
			nonmodalAlbumsTVC.newCollectionDetector!.shouldDetectNewCollectionsOnNextViewWillAppear = true
		}
		
		super.prepare(for: segue, sender: sender)
	}
	
}
