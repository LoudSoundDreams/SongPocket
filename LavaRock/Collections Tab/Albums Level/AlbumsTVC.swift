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
	@IBOutlet var moveAlbumsHereButton: UIBarButtonItem!
	
	// Variables
	var albumMoverClipboard: AlbumMoverClipboard?
	var newCollectionDetector: MovedAlbumsToNewCollectionDetector?
	
	// MARK: - Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		coreDataEntityName = "Album"
	}
	
	override func setUpUI() {
		super.setUpUI()
		
		refreshNavigationItemTitle()
		
		if let albumMoverClipboard = albumMoverClipboard {
			navigationItem.prompt = albumMoverClipboard.navigationItemPrompt
			navigationItem.rightBarButtonItem = cancelMoveAlbumsButton
			
			tableView.allowsSelection = false
			
			navigationController?.isToolbarHidden = false
			
		} else {
			navigationItemButtonsEditingModeOnly = [floatToTopButton, startMovingAlbumsButton]
			
			navigationController?.isToolbarHidden = true
		}
	}
	
	func refreshNavigationItemTitle() {
		if let containingCollection = containerOfData as? Collection {
			title = containingCollection.title
		}
	}
	
	// MARK: Setup Events
	
	@IBAction func unwindToAlbumsAfterMovingAlbums(_ unwindSegue: UIStoryboardSegue) {
		refreshDataAndViews() // Exits this collection if it's now empty.
		isEditing = false // You need to do this after refreshDataAndViews(), or you'll break the animation where we remove the albums that you moved out. This might be because our override of setEditing saves the context when exiting editing mode.
	}
	
	@IBAction func unwindToAlbumsFromEmptyAlbum(_ unwindSegue: UIStoryboardSegue) {
	}
	
	// MARK: - Events
	
	override func refreshNavigationBarButtons() {
		super.refreshNavigationBarButtons()
		
		if isEditing {
			updateStartMovingAlbumsButton()
		}
	}
	
	private func updateStartMovingAlbumsButton() {
		startMovingAlbumsButton.isEnabled = indexedLibraryItems.count > 0
		if tableView.indexPathsForSelectedRows == nil {
			startMovingAlbumsButton.title = "Move All"
		} else {
			startMovingAlbumsButton.title = "Move"
		}
	}
	
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
