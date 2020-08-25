//
//  Editing (SongsTVC).swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit

extension SongsTVC {
	
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
