//
//  SongsTVC.swift
//  LavaRock
//
//  Created by h on 2020-05-04.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import CoreData

final class SongsTVC: LibraryTableViewController {
	
	/*
	WARNING: This class contains a hack on activeLibraryItems, in order to use a regular table view cell as a non-sticky "header".
	
	The header, which contains the artwork and the "Add All to Deck" button, should self-size.
	**It would be cleaner** to assign the header to tableView.tableHeaderView and write code to make it self-size.
	
	Another option is to let the table view do the self-sizing, by using a section header or a regular cell as the header.
	(Note: you can set a UITableViewCell to tableView.tableHeaderView, but it still won't automatically self-size.)
	
	Using a section header (in tableView(_:viewForHeaderInSection:)) provides self-sizing without interfering with the table view data. But with UITableView.Style.plain, the header stays onscreen, which doesn't work because it's huge.
	
	**Instead**, I've used the regular cell at IndexPath [0,0] as the "header".
	This requires hacking activeLibraryItems to accommodate anything involving IndexPaths. This is the hack:
	- As soon as activeLibraryItems is first loaded in loadViaCurrentManagedObjectContext(), insert a dummy duplicate of the object at [0] to index 0.
		This makes activeLibraryItems.count match the number of rows, and makes activeLibraryItems[indexPath.row] reference the right object without any offset.
		Nothing should access that dummy duplicate object.
	- Whenever updating the "index" attributes of the NSManagedObjects in activeLibraryItems, set 0 to the first object after the dummy duplicate object, and count up from there.
		The "index" attribute of the dummy duplicate object in [0] is transparently updated to match that of its counterpart, which is elsewhere in activeLibraryItems.
	
	**This hack (probably) makes it harder** to adopt UITableViewDiffableDataSource and NSFetchedResultsController.
	Also, editing commands that you can apply on "all items" without selecting them first, like sorting, don't work right.
	*/
	
	let numberOfUneditableRowsAtTopOfSection = 2
	
	// MARK: Property observers
	
	override func didSetActiveLibraryItems() {
		for index in 0..<activeLibraryItems.count {
			activeLibraryItems[index].setValue(index - numberOfUneditableRowsAtTopOfSection, forKey: "index")
		}
	}
	
	// MARK: Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		coreDataEntityName = "Song"
	}
	
	// MARK: Loading data
	
	override func loadViaCurrentManagedObjectContext() {
		super.loadViaCurrentManagedObjectContext()
		
		for _ in 1...numberOfUneditableRowsAtTopOfSection {
			activeLibraryItems.insert(activeLibraryItems[0], at: 0)
		}
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return activeLibraryItems.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.row == 0 {
			let artworkCell = tableView.dequeueReusableCell(withIdentifier: "Artwork Cell") as! SongsArtworkCell
			
			// Get the data to put into the cell.
			let album = containerOfData as! Album
			
			// Put the data into the cell.
			artworkCell.artworkImageView.image = UIImage(named: album.sampleArtworkTitle!)
			
			return artworkCell
			
		} else if indexPath.row == 1 {
			let headerCell = tableView.dequeueReusableCell(withIdentifier: "Header Cell") as! SongsHeaderCell
			
			// Get the data to put into the cell.
			let album = containerOfData as! Album
			
			// Put the data into the cell.
			headerCell.albumArtistLabel.text = album.albumArtist ?? "Unknown Album Artist"
			headerCell.yearLabel.text = String(album.year)
			headerCell.addAllToDeckButton.isEnabled = !isEditing
			
			return headerCell
			
		} else {
			let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! SongCell
			
			// Get the data to put into the cell.
			let song = activeLibraryItems[indexPath.row] as! Song
			
			// Put the data into the cell.
			cell.trackNumberLabel.text = String(song.trackNumber)
			cell.titleLabel.text = song.title
			
			return cell
		}
	}
	
	// MARK: Events
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		if !isEditing {
			if let headerCell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? SongsHeaderCell {
				headerCell.addAllToDeckButton.isEnabled = false
			}
		}
		
		super.setEditing(editing, animated: animated)
		
		if !isEditing {
			if let headerCell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? SongsHeaderCell {
				headerCell.addAllToDeckButton.isEnabled = true
			}
		}
	}
	
	override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
		if indexPath.row < numberOfUneditableRowsAtTopOfSection {
			return nil
		} else {
			return indexPath
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		super.tableView(tableView, didSelectRowAt: indexPath)
		
		if !isEditing {
			tableView.deselectRow(at: indexPath, animated: true) //
		}
	}
	
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return indexPath.row >= numberOfUneditableRowsAtTopOfSection
	}
	
	// MARK: Rearranging
	
	override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
		if proposedDestinationIndexPath.row < numberOfUneditableRowsAtTopOfSection {
			return IndexPath(
				row: numberOfUneditableRowsAtTopOfSection,
				section: proposedDestinationIndexPath.section
			)
		} else {
			return proposedDestinationIndexPath
		}
	}
	
	// MARK: Moving rows to top
	
	override func moveSelectedItemsToTop() {
		moveItemsUp(from: tableView.indexPathsForSelectedRows, to: IndexPath(row: numberOfUneditableRowsAtTopOfSection, section: 0))
	}
	
}
