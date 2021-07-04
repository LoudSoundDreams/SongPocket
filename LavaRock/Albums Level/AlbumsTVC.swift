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
		style: .plain,
		target: self,
		action: #selector(startMovingAlbums))
	private lazy var moveAlbumsHereButton = UIBarButtonItem(
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
		}
	}
	
	final override func refreshNavigationItemTitle() {
		guard let containingCollection = sectionOfLibraryItems.container as? Collection else { return }
		title = containingCollection.title
	}
	
	// MARK: Setup Events
	
	@IBAction func unwindToAlbumsFromEmptyAlbum(_ unwindSegue: UIStoryboardSegue) {
	}
	
	// MARK: - Starting Moving Albums
	
	@objc private func startMovingAlbums() {
		
		// Prepare a Collections view to present modally.
		
		guard
			let modalCollectionsNC = storyboard!.instantiateViewController(withIdentifier: "Collections NC") as? UINavigationController,
			let modalCollectionsTVC = modalCollectionsNC.viewControllers.first as? CollectionsTVC
		else {
			return
		}
		
		// Initialize an AlbumMoverClipboard for the modal Collections view.
		
		guard let idOfSourceCollection = sectionOfLibraryItems.container?.objectID else { return }
		
		// Note the Albums to move, and to not move.
		var idsOfAlbumsToMove = [NSManagedObjectID]()
		var idsOfAlbumsToNotMove = [NSManagedObjectID]()
		if tableView.indexPathsForSelectedRowsNonNil.isEmpty {
			idsOfAlbumsToMove = sectionOfLibraryItems.items.map { $0.objectID }
		} else {
			for indexPath in indexPaths(forIndexOfSectionOfLibraryItems: 0) {
				let album = libraryItem(for: indexPath)
				if tableView.indexPathsForSelectedRowsNonNil.contains(indexPath) { // If the row is selected.
					idsOfAlbumsToMove.append(album.objectID)
				} else { // The row is not selected.
					idsOfAlbumsToNotMove.append(album.objectID)
				}
			}
		}
		modalCollectionsTVC.albumMoverClipboard = AlbumMoverClipboard(
			idOfSourceCollection: idOfSourceCollection,
			idsOfAlbumsBeingMoved: idsOfAlbumsToMove,
			idsOfAlbumsNotBeingMoved: idsOfAlbumsToNotMove,
			delegate: self
		)
		
		// Make the destination operate in a child managed object context, so that you can cancel without saving your changes.
		let childManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		childManagedObjectContext.parent = managedObjectContext
		modalCollectionsTVC.managedObjectContext = childManagedObjectContext
		
		present(modalCollectionsNC, animated: true)
		
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
