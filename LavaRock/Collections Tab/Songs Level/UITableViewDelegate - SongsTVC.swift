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
		super.tableView(tableView, didSelectRowAt: indexPath) // Includes refreshBarButtons().
		
		if !isEditing {
			let song = indexedLibraryItems[indexPath.row - numberOfRowsAboveIndexedLibraryItems] as! Song
			showSongActions(for: song)
			// This leaves the row selected while the action sheet is onscreen, as it should be.
			// You must eventually deselect the row (and set isPresentingSongActions = false) in every possible branch from here.
		}
	}
	
	override func refreshAccessibilityTraitsAfterDidSelectRow(at indexPath: IndexPath) {
		guard let cell = tableView.cellForRow(at: indexPath) else { return }
		cell.accessibilityTraits = [.selected, .button]
	}
	
	// MARK: Deselecting
	
	override func refreshAccessibilityTraitsAfterDidDeselectRow(at indexPath: IndexPath) {
		if let cell = tableView.cellForRow(at: indexPath) as? SongCell {
			cell.resetAccessibilityTraits()
		} else if let cell = tableView.cellForRow(at: indexPath) as? SongCellWithDifferentArtist {
			cell.resetAccessibilityTraits()
		}
	}
	
}
