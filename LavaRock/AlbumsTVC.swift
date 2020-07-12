//
//  AlbumsTVC.swift
//  LavaRock
//
//  Created by h on 2020-04-28.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import CoreData

final class AlbumsTVC: LibraryTableViewController {
	
	static let rowHeightInPoints = 44 * 3
	@IBOutlet var startMovingAlbumsButton: UIBarButtonItem!
	
	// MARK: Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		coreDataEntityName = "Album"
	}
	
	// MARK: Setting up UI
	
	override func setUpUI() {
		super.setUpUI()
		
		navigationItem.leftBarButtonItems = nil // Removes "Move All" button added in storyboard
		tableView.rowHeight = CGFloat(Self.rowHeightInPoints)
		
		if collectionsNC.isInMoveAlbumsMode {
			tableView.allowsSelection = false
		} else {
			barButtonItemsEditMode = [floatToTopButton, startMovingAlbumsButton]
		}
	}
	
	// MARK: Loading data
	
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		// Get the data to put into the cell.
		let album = activeLibraryItems[indexPath.row] as! Album
		
		let albumArtwork: UIImage?
		if let jpegdata = album.downsampledArtwork {
			albumArtwork = UIImage(data: jpegdata, scale: UIScreen.main.scale)
			// .scale is the ratio of rendered pixels to points (3.0 on an iPhone Plus).
			// .nativeScale is the ratio of physical pixels to points (2.608 on an iPhone Plus).
		} else {
			albumArtwork = UIImage(named: (album.sampleArtworkTitle!)) //
		}
		let albumTitle = album.title
		let albumYearText = String(album.year)
		
		// Make, configure, and return the cell.
//		if #available(iOS 14, *) {
//			let cell = tableView.dequeueReusableCell(withIdentifier: "Basic Cell", for: indexPath)
//
//			var configuration = UIListContentConfiguration.subtitleCell()
//			configuration.image = albumArtwork
//			configuration.text = albumTitle
//			configuration.secondaryText = albumYearText
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
//		} else { // iOS 13 or earlier
			let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! AlbumCell
			
			cell.artworkImageView.image = albumArtwork
			cell.titleLabel.text = albumTitle
			cell.yearLabel.text = albumYearText
			
			// Customize the cell.
			if collectionsNC.isInMoveAlbumsMode {
				cell.accessoryType = .none
			}
			
			return cell
//		}
    }
	
	// MARK: Events
	
	override func viewDidAppear(_ animated: Bool) {
		if !collectionsNC.isInMoveAlbumsMode && activeLibraryItems.isEmpty {
			performSegue(withIdentifier: "Exit Empty Collection", sender: nil)
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "Moved Albums",
			let destination = segue.destination as? AlbumsTVC,
			collectionsNC.didMoveAlbumsToNewCollections {
			destination.collectionsNC.didMoveAlbumsToNewCollections = true
		}
		
		super.prepare(for: segue, sender: sender)
	}
	
	// MARK: “Move albums” mode
	
	// Starting moving albums
	
	@IBAction func startMovingAlbums(_ sender: UIBarButtonItem) {
		
		// Prepare a Collections view in "move albums" mode.
		let moveAlbumsNC = storyboard!.instantiateViewController(withIdentifier: "Collections NC") as! CollectionsNC
		moveAlbumsNC.isInMoveAlbumsMode = true
		moveAlbumsNC.moveAlbumsModePrompt = moveAlbumsModePrompt()
		
		// Note the albums to move.
		moveAlbumsNC.indexesOfAlbumsBeingMoved = selectedOrAllRowsInOrder(numberOfRows: activeLibraryItems.count)
		moveAlbumsNC.originalIndexOfCollectionThatAlbumsAreBeingMovedFrom = Int((containerOfData as! Collection).index)
		
		// Make the destination operate in a child managed object context, so that you can cancel without saving your changes.
		let childManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		childManagedObjectContext.parent = collectionsNC.managedObjectContext
		moveAlbumsNC.managedObjectContext = childManagedObjectContext
		
		present(moveAlbumsNC, animated: true, completion: nil)
	}
	
	func moveAlbumsModePrompt() -> String {
		var numberOfAlbumsToMove = 0
		if let selectedIndexPaths = tableView.indexPathsForSelectedRows {
			numberOfAlbumsToMove = selectedIndexPaths.count
		} else {
			numberOfAlbumsToMove = activeLibraryItems.count
		}
		
		if numberOfAlbumsToMove == 1 {
			return "Chooose a collection to move 1 album to."
		} else {
			return "Choose a collection to move \(numberOfAlbumsToMove) albums to."
		}
	}
	
	// Ending moving albums
	
	@IBAction func moveAlbumsHere(_ sender: UIBarButtonItem) {
		
		guard collectionsNC.indexesOfAlbumsBeingMoved != nil else {
			fatalError("In the “move albums” sheet, the user tapped Move Here, but the list of albums to move was empty.")
		}
		
		if activeLibraryItems.isEmpty {
			collectionsNC.didMoveAlbumsToNewCollections = true
		}
		
		// Find out if we're moving albums to the collection they were already in.
		// If so, we'll use the "move rows to top" logic.
		let currentContainerIndex = Int((containerOfData as! Collection).index)
		let isMovingToSameCollection =
			!activeLibraryItems.isEmpty && // "We're not in the new (empty) collection"
			currentContainerIndex == collectionsNC.originalIndexOfCollectionThatAlbumsAreBeingMovedFrom
		
		// Get the albums to move.
		
		// Fetch all the albums in the collection that albums are being moved from.
		let albumsInCollectionToMoveFrom = albumsIn(collectionIndex: collectionsNC.originalIndexOfCollectionThatAlbumsAreBeingMovedFrom!)
		
		// Split that into the albums we're moving and the albums we're not moving.
		var albumsToMove = [Album]()
		var albumsNotToMove = [Album]()
		for index in 0..<albumsInCollectionToMoveFrom.count {
			let album = albumsInCollectionToMoveFrom[index]
			if collectionsNC.indexesOfAlbumsBeingMoved!.contains(index) {
				albumsToMove.append(album)
			} else {
				albumsNotToMove.append(album)
			}
		}
		
		// Apply the changes.
		
		// Update the indexes of the albums we aren't moving, within their collection.
		// Almost identical to the property observer for activeLibraryItems.
		for index in 0..<albumsNotToMove.count {
			albumsNotToMove[index].setValue(index, forKey: "index")
		}
		
		func saveParentManagedObjectContext() {
			do {
				try collectionsNC.managedObjectContext.parent!.save()
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
			collectionsNC.saveCurrentManagedObjectContext()
			saveParentManagedObjectContext()
		}
		
		// If we're moving albums to the collection they're already in, prepare for "move rows to top".
		var indexPathsToMoveToTop = [IndexPath]()
		if isMovingToSameCollection {
			for index in collectionsNC.indexesOfAlbumsBeingMoved! {
				indexPathsToMoveToTop.append(IndexPath(row: index, section: 0))
			}
		}
		
		// Update the table view.
		tableView.performBatchUpdates( {
			if isMovingToSameCollection {
				// You need to do this in performBatchUpdates so that the sheet dismisses after the rows finish animating.
				moveItemsUp(from: indexPathsToMoveToTop, to: IndexPath(row: 0, section: 0))
				collectionsNC.saveCurrentManagedObjectContext()
				saveParentManagedObjectContext()
			} else {
				let indexPaths = indexPathsEnumeratedIn(section: 0, firstRow: 0, lastRow: albumsToMove.count - 1)
				tableView.insertRows(at: indexPaths, with: .middle)
			}
			
		}, completion: { _ in
			self.performSegue(withIdentifier: "Moved Albums", sender: self)
		})
		
	}
	
	func albumsIn(collectionIndex: Int) -> [Album] {
		var result = [Album]()
		let predicateGivenContainerIndex = NSPredicate(format: "container.index == %i", collectionsNC.originalIndexOfCollectionThatAlbumsAreBeingMovedFrom!)
		let previousPredicate = coreDataFetchRequest.predicate
		coreDataFetchRequest.predicate = predicateGivenContainerIndex
		do {
			result = try collectionsNC.managedObjectContext.fetch(coreDataFetchRequest) as! [Album]
		} catch {
			fatalError("Couldn’t fetch the albums to move after the user tapped Move Here: \(error)")
		}
		coreDataFetchRequest.predicate = previousPredicate
		return result
	}
	
	@IBAction func unwindToAlbums(_ unwindSegue: UIStoryboardSegue) {
		isEditing = false
		
		loadViaCurrentManagedObjectContext()
		tableView.reloadData()
		
		viewDidAppear(true) // Unwinds to Collections if you moved all the albums out
	}
	
	// MARK: Updating UI to reflect current state
	
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
	
}
