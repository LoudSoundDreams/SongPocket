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
	NavigationItemTitleCustomizer
{
	
	// MARK: - Properties
	
	// "Constants"
	@IBOutlet var startMovingAlbumsButton: UIBarButtonItem!
	@IBOutlet var moveAlbumsHereButton: UIBarButtonItem!
	
	// Variables
	var moveAlbumsClipboard: MoveAlbumsClipboard?
	var newCollectionDetector: MovedAlbumsToNewCollectionDetector?
	
	// MARK: - Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		coreDataEntityName = "Album"
	}
	
	override func setUpUI() {
		super.setUpUI()
		
		customizeNavigationItemTitle()
		
		if let moveAlbumsClipboard = moveAlbumsClipboard {
			navigationItem.prompt = MoveAlbumsClipboard.moveAlbumsModePrompt(numberOfAlbumsBeingMoved: moveAlbumsClipboard.idsOfAlbumsBeingMoved.count)
			navigationItem.rightBarButtonItem = cancelMoveAlbumsButton
			
			tableView.allowsSelection = false
			
			navigationController?.isToolbarHidden = false
			
		} else {
			navigationItemButtonsEditModeOnly = [floatToTopButton, startMovingAlbumsButton]
			
			navigationController?.isToolbarHidden = true
		}
	}
	
	func customizeNavigationItemTitle() {
		if let containingCollection = containerOfData as? Collection {
			title = containingCollection.title
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if moveAlbumsClipboard != nil {
		} else {
//			if fetchedResultsController?.fetchedObjects?.count == 0 {
			if activeLibraryItems.isEmpty {
				performSegue(withIdentifier: "Exit Empty Collection", sender: nil)
			}
		}
	}
	
	@IBAction func unwindToAlbums(_ unwindSegue: UIStoryboardSegue) {
		isEditing = false
		
		loadSavedLibraryItems()
		tableView.reloadData()
		
		viewDidAppear(true) // Exits this collection if it's now empty.
	}
	
	// MARK: - Events
	
	override func refreshNavigationBarButtons() {
		super.refreshNavigationBarButtons()
		
		if isEditing {
			updateStartMovingAlbumsButton()
		}
	}
	
	func updateStartMovingAlbumsButton() {
		if tableView.indexPathsForSelectedRows == nil {
			startMovingAlbumsButton.title = "Move All"
		} else {
			startMovingAlbumsButton.title = "Move"
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "Moved Albums",
		   let nonmodalAlbumsTVC = segue.destination as? AlbumsTVC,
		   let newCollectionDetector = newCollectionDetector,
		   newCollectionDetector.shouldDetectNewCollectionsOnNextViewWillAppear
		{
			nonmodalAlbumsTVC.newCollectionDetector!.shouldDetectNewCollectionsOnNextViewWillAppear = true
		}
		
		super.prepare(for: segue, sender: sender)
	}
	
}
