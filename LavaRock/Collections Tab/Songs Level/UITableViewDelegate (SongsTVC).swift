//
//  UITableViewDelegate (SongsTVC).swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit

extension SongsTVC {
	
	override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
		if indexPath.row < numberOfUneditableRowsAtTopOfSection {
			return nil
		} else {
			return indexPath
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		super.tableView(tableView, didSelectRowAt: indexPath) // Why do we need this?
		
		if !isEditing {
//			guard let song = fetchedResultsController?.object(at: indexPath) as? Song else {
//				return
//			}
			let song = activeLibraryItems[indexPath.row] as! Song
			showSongActions(for: song)
			// The row should stay selected while the action sheet is onscreen.
			// You must eventually deselect the row in every possible branch from here.
		}
	}
	
	// MARK: - Rearranging
	
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
	
}
