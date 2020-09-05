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

final class SongsTVC:
	LibraryTVC,
	NavigationItemTitleCustomizer
{
	
	/*
	WARNING: This class contains a hack on activeLibraryItems, in order to use a regular table view cell as a non-sticky "header".
	
	The header, which contains the artwork, album artist, and release date, should self-size.
	**It would be cleaner** to assign the header to tableView.tableHeaderView and write code to make it self-size.
	
	Another option is to let the table view do the self-sizing, by using a section header or a regular cell as the header.
	(Note: you can set a UITableViewCell to tableView.tableHeaderView, but it still won't automatically self-size.)
	
	Using a section header (in tableView(_:viewForHeaderInSection:)) provides self-sizing without interfering with the table view data. But with UITableView.Style.plain, the header stays onscreen, which doesn't work because it's huge.
	
	**Instead**, I've used the regular cell at IndexPath [0,0] as the "header".
	This requires hacking activeLibraryItems to accommodate anything involving IndexPaths. This is the hack:
	- As soon as activeLibraryItems is first loaded in reloadActiveLibraryItems(), insert a dummy duplicate of the object at [0] to index 0.
		- This makes activeLibraryItems.count match the number of rows, and makes activeLibraryItems[indexPath.row] reference the right object without any offset.
		- Nothing should access that dummy duplicate object.
	- Whenever updating the "index" attributes of the NSManagedObjects in activeLibraryItems, set 0 to the first object after the dummy duplicate object, and count up from there.
		- The "index" attribute of the dummy duplicate object in [0] is transparently updated to match that of its counterpart, which is elsewhere in activeLibraryItems.
	
	An alternative would be to leave activeLibraryItems alone so that it would have the same number of items as songs in this view, and get songs from it with activeLibraryItems[indexPath.row - numberOfUneditableRowsAtTopOfSection] instead of activeLibraryItems[indexPath.row].
	But some methods in the superclass, LibraryTVC, assume that activeLibraryItems[indexPath.row] will get the right items, like sorting, and we would have to hack those too. It's better to contain the hack to this class.
	
	Anything that involves activeLibraryItems or IndexPaths probably won't work right without more hacking.
	*/
	
	// MARK: - Properties
	
	// Constants
	let numberOfUneditableRowsAtTopOfSection = 2
	
	// MARK: Property Observers
	
	override func didSetActiveLibraryItems() {
		for index in 0..<activeLibraryItems.count {
			activeLibraryItems[index].setValue(
				index - numberOfUneditableRowsAtTopOfSection,
				forKey: "index")
		}
	}
	
	// MARK: - Setup
	
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
	
	override func reloadActiveLibraryItems() {
		super.reloadActiveLibraryItems()

		for _ in 1...numberOfUneditableRowsAtTopOfSection {
			activeLibraryItems.insert(activeLibraryItems[0], at: 0)
		}
	}
	
	// MARK: - Taking Action on Songs
	
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
		
		if Int(song.index) + numberOfUneditableRowsAtTopOfSection + 1 >= tableView.numberOfRows(inSection: 0) { // For example, a Song with an "index" attribute of 0 is the last song if numberOfUneditableRowsAtTopOfSection == 2 and there are 3 rows in total.
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
	
}
