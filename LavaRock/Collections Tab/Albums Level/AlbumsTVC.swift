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
	
	override func viewDidAppear(_ animated: Bool) {
		if albumMoverClipboard != nil {
		} else {
//			if fetchedResultsController?.fetchedObjects?.count == 0 {
			if indexedLibraryItems.isEmpty && !shouldRefreshOnNextViewDidAppear {
				performSegue(withIdentifier: "Moved All Albums Out", sender: nil)
			}
		}
		
		super.viewDidAppear(animated)
	}
	
	@IBAction func unwindToAlbumsAfterMovingAlbums(_ unwindSegue: UIStoryboardSegue) {
		isEditing = false
		
		reloadIndexedLibraryItems()
		tableView.reloadData()
		
		viewDidAppear(true) // Exits this collection if it's now empty.
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
