//
//  UITableViewDelegate (CollectionsTVC).swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit

extension CollectionsTVC {
	
	override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
		if let moveAlbumsClipboard = moveAlbumsClipboard {
			let collectionID = activeLibraryItems[indexPath.row].objectID
			if collectionID == moveAlbumsClipboard.idOfCollectionThatAlbumsAreBeingMovedOutOf {
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
