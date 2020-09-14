//
//  UITableViewDelegate - CollectionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit

extension CollectionsTVC {
	
	// WARNING: This doesn't accommodate numberOfRowsAboveIndexedLibraryItems. You might want to call super.
	override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
		if let albumMoverClipboard = albumMoverClipboard {
			let collectionID = indexedLibraryItems[indexPath.row - numberOfRowsAboveIndexedLibraryItems].objectID
			if collectionID == albumMoverClipboard.idOfCollectionThatAlbumsAreBeingMovedOutOf {
				return nil
			} else {
				return indexPath
			}
			
		} else {
			return indexPath
		}
	}
	
	// MARK: - Editing
	
	override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
		renameCollection(at: indexPath)
	}
	
}
