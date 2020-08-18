//
//  AlbumsTVC.swift
//  LavaRock
//
//  Created by h on 2020-04-28.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import CoreData

final class AlbumsTVC: LibraryTVC, AlbumMover {
	
	// MARK: Properties
	
	// "Constants"
	static let rowHeightInPoints = 44 * 3
	@IBOutlet var startMovingAlbumsButton: UIBarButtonItem!
	
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
		
		tableView.rowHeight = CGFloat(Self.rowHeightInPoints)
		
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
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if moveAlbumsClipboard != nil {
		} else {
			if activeLibraryItems.isEmpty {
				performSegue(withIdentifier: "Exit Empty Collection", sender: nil)
			}
		}
	}
	
	// MARK: Loading Data
	
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		// Get the data to put into the cell.
		
		let album = activeLibraryItems[indexPath.row] as! Album
		
		var albumImage: UIImage? = nil // nil removes the placeholder image in the storyboard.
		coreDataManager.managedObjectContext.performAndWait {
			let songsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Song")
			songsFetchRequest.predicate = NSPredicate(format: "container == %@", album)
			songsFetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
			// TO DO: Is this wasteful?
			let allSongs = coreDataManager.managedObjects(for: songsFetchRequest) as! [Song]
			let firstSong = allSongs.first
			albumImage = firstSong?.artworkImage() // TO DO: If the first song doesn't have any artwork, or it doesn't exist anymore, try the next song until we either get some artwork or reach the last song.
		}
		
		let albumTitle = album.titleOrPlaceholder()
		
		let albumYearText = album.releaseDateFormatted()
		
		// Make, configure, and return the cell.
		
//		if #available(iOS 14, *) {
//			let cell = tableView.dequeueReusableCell(withIdentifier: "Basic Cell", for: indexPath)
//
//			var configuration = UIListContentConfiguration.subtitleCell()
//			configuration.image = albumImage
//			configuration.text = albumTitle
//			configuration.secondaryText = albumYear
//
//			cell.contentConfiguration = configuration
//
//			// Customize the cell.
//			if collectionsNC.isInMoveAlbumsMode {
//				cell.accessoryType = .none
//			} else {
//				cell.accessoryType = .disclosureIndicator
//			}
//
//			return cell
//
//		} else { // iOS 13 and earlier
		let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! AlbumCell
		
		cell.artworkImageView.image = albumImage
		cell.titleLabel.text = albumTitle
		cell.yearLabel.text = albumYearText
		
		// Customize the cell.
		if moveAlbumsClipboard != nil {
			cell.accessoryType = .none
		}
		
		return cell
//		}
    }
	
	// MARK: - Events
	
	override func updateBarButtonItems() {
		super.updateBarButtonItems()
		
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
	

	// MARK: - “Move Albums" Mode
	
	// Starting moving albums
	
	@IBAction func startMovingAlbums(_ sender: UIBarButtonItem) {
		
		// Prepare a Collections view to present modally.
		
		let modalCollectionsNC = storyboard!.instantiateViewController(withIdentifier: "Collections NC") as! UINavigationController
		let modalCollectionsTVC = modalCollectionsNC.viewControllers.first as! CollectionsTVC
		
		// Initialize a MoveAlbumsClipboard for the modal Collections view.
		
		let idOfSourceCollection = containerOfData!.objectID
		
		// Note the albums to move, and to not move.
		
		var idsOfAlbumsToMove = [NSManagedObjectID]()
		var idsOfAlbumsToNotMove = [NSManagedObjectID]()
		
		if let selectedIndexPaths = tableView.indexPathsForSelectedRows { // If any rows are selected.
			for indexPath in indexPathsEnumeratedIn(section: 0, firstRow: 0, lastRow: activeLibraryItems.count - 1) {
				let album = activeLibraryItems[indexPath.row] as! Album
				if selectedIndexPaths.contains(indexPath) { // If the row is selected.
					idsOfAlbumsToMove.append(album.objectID)
				} else { // The row is not selected.
					idsOfAlbumsToNotMove.append(album.objectID)
				}
			}
		} else { // No rows are selected.
			for album in activeLibraryItems {
				idsOfAlbumsToMove.append(album.objectID)
			}
		}
		
		modalCollectionsTVC.moveAlbumsClipboard = MoveAlbumsClipboard(
			idOfCollectionThatAlbumsAreBeingMovedOutOf: idOfSourceCollection,
			idsOfAlbumsBeingMoved: idsOfAlbumsToMove,
			idsOfAlbumsNotBeingMoved: idsOfAlbumsToNotMove
		)
		
		// Make the destination operate in a child managed object context, so that you can cancel without saving your changes.
		
		let childManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType) // Do this from within the MoveAlbumsClipboard, to guarantee it's done on the right thread.
		childManagedObjectContext.parent = coreDataManager.managedObjectContext
		
		modalCollectionsTVC.coreDataManager = CoreDataManager(managedObjectContext: childManagedObjectContext)
		
		present(modalCollectionsNC, animated: true, completion: nil)
		
	}
	
	// Ending moving albums
	
	@IBAction func moveAlbumsHere(_ sender: UIBarButtonItem) {
		
		guard let moveAlbumsClipboard = moveAlbumsClipboard else {
			return
		}
		
		if activeLibraryItems.isEmpty {
			newCollectionDetector!.shouldDetectNewCollectionsOnNextViewWillAppear = true
		}
		
		// Get the albums to move, and to not move.
		var albumsToMove = [Album]()
		for albumID in moveAlbumsClipboard.idsOfAlbumsBeingMoved {
			albumsToMove.append(coreDataManager.managedObjectContext.object(with: albumID) as! Album)
		}
		var albumsToNotMove = [Album]()
		for albumID in moveAlbumsClipboard.idsOfAlbumsNotBeingMoved {
			albumsToNotMove.append(coreDataManager.managedObjectContext.object(with: albumID) as! Album)
		}
		
		// Find out if we're moving albums to the collection they were already in.
		// If so, we'll use the "move rows to top" logic.
		let isMovingToSameCollection = activeLibraryItems.contains(albumsToMove[0])
		
		// Apply the changes.
		
		// Update the indexes of the albums we aren't moving, within their collection.
		// Almost identical to the property observer for activeLibraryItems.
		for index in 0..<albumsToNotMove.count {
			albumsToNotMove[index].setValue(index, forKey: "index")
		}
		
		func saveParentManagedObjectContext() {
			do {
				try coreDataManager.managedObjectContext.parent!.save()
			} catch {
				fatalError("Crashed while trying to commit changes, just before dismissing the “move albums” sheet: \(error)")
			}
		}
		
		if !isMovingToSameCollection {
			for index in 0..<albumsToMove.count {
				let album = albumsToMove[index]
				album.container = containerOfData as? Collection
				activeLibraryItems.insert(album, at: index)
			}
			coreDataManager.save()
			saveParentManagedObjectContext()
		}
		
		// If we're moving albums to the collection they're already in, prepare for "move rows to top".
		var indexPathsToMoveToTop = [IndexPath]()
		if isMovingToSameCollection {
			for album in albumsToMove {
				let index = activeLibraryItems.firstIndex(of: album)
				guard index != nil else {
					fatalError("It looks like we’re moving albums to the collection they’re already in, but one of the albums we’re moving isn’t here.")
				}
				indexPathsToMoveToTop.append(IndexPath(row: index!, section: 0))
			}
		}
		
		// Update the table view.
		tableView.performBatchUpdates( {
			if isMovingToSameCollection {
				// You need to do this in performBatchUpdates so that the sheet dismisses after the rows finish animating.
				moveItemsUp(from: indexPathsToMoveToTop, to: IndexPath(row: 0, section: 0))
				coreDataManager.save()
				saveParentManagedObjectContext()
			} else {
				let indexPaths = indexPathsEnumeratedIn(section: 0, firstRow: 0, lastRow: albumsToMove.count - 1)
				tableView.insertRows(at: indexPaths, with: .middle)
			}
			
		}, completion: { _ in
			self.performSegue(withIdentifier: "Moved Albums", sender: self)
		})
		
	}
	
	@IBAction func unwindToAlbums(_ unwindSegue: UIStoryboardSegue) {
		isEditing = false
		
		loadSavedLibraryItems()
		tableView.reloadData()
		
		viewDidAppear(true) // Exits this collection if it's now empty.
	}
	
}
