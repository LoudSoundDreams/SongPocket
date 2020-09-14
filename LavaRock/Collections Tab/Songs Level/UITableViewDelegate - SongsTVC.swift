//
//  UITableViewDelegate - SongsTVC.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit

extension SongsTVC {
	
	// MARK: - Selecting
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		super.tableView(tableView, didSelectRowAt: indexPath) // Why do we need this?
		
		if !isEditing {
//			guard let song = fetchedResultsController?.object(at: indexPath) as? Song else {
//				return
//			}
			let song = indexedLibraryItems[indexPath.row - numberOfRowsAboveIndexedLibraryItems] as! Song
			showSongActions(for: song)
			// This leaves the row selected while the action sheet is onscreen, as it should be.
			// You must eventually deselect the row (and set isPresentingSongActions = false) in every possible branch from here.
		}
	}
	
}
