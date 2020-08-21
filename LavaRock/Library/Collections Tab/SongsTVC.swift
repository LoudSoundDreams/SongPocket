//
//  SongsTVC.swift
//  LavaRock
//
//  Created by h on 2020-05-04.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import CoreData
import MediaPlayer

final class SongsTVC: LibraryTVC, NavigationItemTitleCustomizer {
	
	/*
	WARNING: This class contains a hack on activeLibraryItems, in order to use a regular table view cell as a non-sticky "header".
	
	The header, which contains the artwork, album artist, and release date, should self-size.
	**It would be cleaner** to assign the header to tableView.tableHeaderView and write code to make it self-size.
	
	Another option is to let the table view do the self-sizing, by using a section header or a regular cell as the header.
	(Note: you can set a UITableViewCell to tableView.tableHeaderView, but it still won't automatically self-size.)
	
	Using a section header (in tableView(_:viewForHeaderInSection:)) provides self-sizing without interfering with the table view data. But with UITableView.Style.plain, the header stays onscreen, which doesn't work because it's huge.
	
	**Instead**, I've used the regular cell at IndexPath [0,0] as the "header".
	This requires hacking activeLibraryItems to accommodate anything involving IndexPaths. This is the hack:
	- As soon as activeLibraryItems is first loaded in loadSavedLibraryItems(), insert a dummy duplicate of the object at [0] to index 0.
		This makes activeLibraryItems.count match the number of rows, and makes activeLibraryItems[indexPath.row] reference the right object without any offset.
		Nothing should access that dummy duplicate object.
	- Whenever updating the "index" attributes of the NSManagedObjects in activeLibraryItems, set 0 to the first object after the dummy duplicate object, and count up from there.
		The "index" attribute of the dummy duplicate object in [0] is transparently updated to match that of its counterpart, which is elsewhere in activeLibraryItems.
	
	**This hack (probably) makes it harder** to adopt UITableViewDiffableDataSource and NSFetchedResultsController.
	Also, any commands that involve activeLibraryItems or IndexPaths probably won't work right without more hacking
	*/
	
	// MARK: Properties
	
	// Constants
	let numberOfUneditableRowsAtTopOfSection = 2
	
	// MARK: Property Observers
	
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
	
	override func setUpUI() {
		super.setUpUI()
		
		customizeNavigationItemTitle()
		navigationItemButtonsEditModeOnly = [floatToTopButton, sortButton]
		sortOptions = ["Track Number"]
	}
	
	func customizeNavigationItemTitle() {
		if let containingAlbum = containerOfData as? Album {
			title = containingAlbum.titleFormattedOrPlaceholder()
		}
	}
	
	// MARK: Loading Data
	
	override func loadSavedLibraryItems() {
		super.loadSavedLibraryItems()
		
		for _ in 1...numberOfUneditableRowsAtTopOfSection {
			activeLibraryItems.insert(activeLibraryItems[0], at: 0)
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.row == 0 {
			
			// Get the data to put into the cell.
			let album = containerOfData as! Album
			let representativeItem = album.mpMediaItemCollection()?.representativeItem
			let cellImage = representativeItem?.artwork?.image(at: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)) // nil removes the placeholder image in the storyboard.
			
			// Make, configure, and return the cell.
			let artworkCell = tableView.dequeueReusableCell(withIdentifier: "Artwork Cell") as! SongsArtworkCell
			artworkCell.artworkImageView.image = cellImage
			return artworkCell
			
		} else if indexPath.row == 1 {
			
			// Should we use placeholders for album artist and release date if they're unknown, or just remove this header cell altogether?
			
			// Get the data to put into the cell.
			let album = containerOfData as! Album
			let cellHeading = album.albumArtistFormattedOrPlaceholder()
			let cellSubtitle = album.releaseDateEstimateFormatted()
			
			// Make, configure, and return the cell.
			let headerCell = tableView.dequeueReusableCell(withIdentifier: "Header Cell Without Button") as! SongsAlbumInfoHeaderCell
			headerCell.albumArtistLabel.text = cellHeading
			headerCell.yearLabel.text = cellSubtitle
			return headerCell
			
		} else {
			
			// Get the data to put into the cell.
			let song = activeLibraryItems[indexPath.row] as! Song
			let cellLeftText = song.trackNumberFromStoredAttributeFormatted()
			let cellRightText = song.titleFormattedOrPlaceholder()
			
			// Make, configure, and return the cell.
//			if #available(iOS 14, *) {
//				let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
//
//				var configuration = UIListContentConfiguration.valueCell()
//				configuration.text = song.title
//				configuration.secondaryText = trackNumberText
//
//				cell.contentConfiguration = configuration
//
//				return cell
//
//			} else { // iOS 13 and earlier
			let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! SongCell
			
			cell.trackNumberLabel.text = cellLeftText
			cell.titleLabel.text = cellRightText
			
			
//				print("for IndexPath \(indexPath), \(String(describing: cell.titleLabel.text)):")
//				print("trackNumberLabel.frame: \(cell.trackNumberLabel.frame)")
//				print("trackNumberLabel.bounds: \(cell.trackNumberLabel.bounds)")
//				print("trackNumberLabel.intrinsicContentSize: \(cell.trackNumberLabel.intrinsicContentSize)")
				//			print("titleLabel.frame: \(cell.titleLabel.frame)")
				//			print("titleLabel.bounds: \(cell.titleLabel.bounds)")
				//			print("titleLabel.intrinsicContentSize: \(cell.titleLabel.intrinsicContentSize)")
//				print("")
			
			
			return cell
//			}
		}
	}
	
	// MARK: Events
	
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
			let song = activeLibraryItems[indexPath.row] as! Song
			showSongActions(for: song)
			// The row should stay selected while the action sheet is onscreen.
			// You must eventually deselect the row in every possible branch from here.
		}
	}
	
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return indexPath.row >= numberOfUneditableRowsAtTopOfSection
	}
	
	// MARK: Taking Action on Songs
	
	func showSongActions(for song: Song) {
		
		// Prepare an action sheet, from top to bottom.
		
		let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		
		let playAlbumStartingHereAction = UIAlertAction(
			title: "Play Starting Here",
			style: .destructive,
			handler: playAlbumStartingAtSelectedSong
		)
		
		let enqueueSongAction = UIAlertAction(
			title: "Add to Queue",
			style: .default,
			handler: enqueueSelectedSong
		)
		
		let enqueueAlbumStartingHereAction = UIAlertAction(
			title: "Add to Queue Starting Here",
			style: .default,
			handler: enqueueAlbumStartingAtSelectedSong
		)
		
		// Disable the actions that we shouldn't offer for the last song in the section.
		
		if Int(song.index) + numberOfUneditableRowsAtTopOfSection + 1 >= activeLibraryItems.count { // For example, with activeLibraryItems.count (the number of rows) == 3 and numberOfUneditableRowsAtTopOfSection == 2, the song at index 0 is the last song.
			enqueueAlbumStartingHereAction.isEnabled = false
		}
		
		actionSheet.addAction(playAlbumStartingHereAction)
		actionSheet.addAction(enqueueAlbumStartingHereAction)
		actionSheet.addAction(enqueueSongAction)
		
		actionSheet.addAction(
			UIAlertAction(
				title: "Cancel",
				style: .cancel,
				handler: { _ in
					self.tableView.deselectAllRows(animated: true)
				}
			)
		)
		
		present(actionSheet, animated: true, completion: nil)
		
	}
	
	func playAlbumStartingAtSelectedSong(_ sender: UIAlertAction) {
		tableView.deselectAllRows(animated: true)
		
	}
	
	func enqueueAlbumStartingAtSelectedSong(_ sender: UIAlertAction) {
		tableView.deselectAllRows(animated: true)
		
	}
	
	func enqueueSelectedSong(_ sender: UIAlertAction) {
		tableView.deselectAllRows(animated: true)
		
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
	
	// MARK: Moving Rows to Top
	
	override func moveSelectedItemsToTop() {
		moveItemsUp(from: tableView.indexPathsForSelectedRows, to: IndexPath(row: numberOfUneditableRowsAtTopOfSection, section: 0))
	}
	
	// MARK: Sorting
	
	// In the parent class, sortSelectedOrAllItems is split into two parts, where the first part is like this stub here, in order to allow this class to inject numberOfUneditableRowsAtTopOfSection. This is bad practice.
	override func sortSelectedOrAllItems(sender: UIAlertAction) {
		let selectedIndexPaths = selectedOrAllIndexPathsSortedIn(section: 0, firstRow: numberOfUneditableRowsAtTopOfSection, lastRow: activeLibraryItems.count - 1)
		sortSelectedOrAllItemsPart2(selectedIndexPaths: selectedIndexPaths, sender: sender)
	}
	
}
