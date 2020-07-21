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
	
	static let impossibleYear = -13800000001 // "nil" value for `year` attribute. Even though the attribute is optional, Swift doesn't treat it as an optional (neither does Objective-C) because "nil" for an integer Core Data attribute is actually a SQL `NULL`, not a Swift `nil`.
	// SampleLibrary uses this number for sample albums without years.
	// AlbumsTVC and SongsTVC leave the "year" field blank if the album's year is this number.
	static let rowHeightInPoints = 44 * 3 // Album class references this to create thumbnails.
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
		
		let image: UIImage?
		if let thumbnailData = album.artworkThumbnail {
			image = UIImage(data: thumbnailData, scale: UIScreen.main.scale)
			// .scale is the ratio of rendered pixels to points (3.0 on an iPhone Plus).
			// .nativeScale is the ratio of physical pixels to points (2.608 on an iPhone Plus).
		} else {
			image = album.sampleArtworkImageFullSize() //
		}
		
		let titleOfAlbum = album.title
		
		let yearText: String?
		if album.year != AlbumsTVC.impossibleYear {
			yearText = String(album.year)
		} else {
			yearText = nil
		}
		
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
			
			cell.artworkImageView.image = image
			cell.titleLabel.text = titleOfAlbum
			cell.yearLabel.text = yearText
			
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
		
		// Note the albums to move, and to not move.
		
		if let selectedIndexPaths = tableView.indexPathsForSelectedRows {
			
			for indexPath in indexPathsEnumeratedIn(section: 0, firstRow: 0, lastRow: activeLibraryItems.count - 1) {
				let album = activeLibraryItems[indexPath.row] as! Album
				if selectedIndexPaths.contains(indexPath) {
					moveAlbumsNC.managedObjectIDsOfAlbumsBeingMoved.append(album.objectID)
				} else { // The row is not selected.
					moveAlbumsNC.managedObjectIDsOfAlbumsNotBeingMoved.append(album.objectID)
				}
			}
			
		} else { // No rows are selected.
			
			for item in activeLibraryItems {
				moveAlbumsNC.managedObjectIDsOfAlbumsBeingMoved.append(item.objectID)
			}
			
		}
		
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
		
		if activeLibraryItems.isEmpty {
			collectionsNC.didMoveAlbumsToNewCollections = true
		}
		
		// Get the albums to move, and to not move.
		var albumsToMove = [Album]()
		for albumID in collectionsNC.managedObjectIDsOfAlbumsBeingMoved {
			albumsToMove.append(collectionsNC.managedObjectContext.object(with: albumID) as! Album)
		}
		var albumsToNotMove = [Album]()
		for albumID in collectionsNC.managedObjectIDsOfAlbumsNotBeingMoved {
			albumsToNotMove.append(collectionsNC.managedObjectContext.object(with: albumID) as! Album)
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
	
	@IBAction func unwindToAlbums(_ unwindSegue: UIStoryboardSegue) {
		isEditing = false
		
		loadActiveLibraryItems()
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
