//
//  UITableView - CollectionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit
import MediaPlayer

extension CollectionsTVC {
	
	// MARK: - Cells
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return super.tableView(tableView, cellForRowAt: indexPath)
		}
		
		if indexPath.row < numberOfRowsAboveIndexedLibraryItems {
			
			return UITableViewCell()
			
		} else { // Return a cell for an item in indexedLibraryItems.
			// Get the data to put into the cell.
			let collection = indexedLibraryItems[indexPath.row - numberOfRowsAboveIndexedLibraryItems] as! Collection
			
			// Make, configure, and return the cell.
			
			let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
			if #available(iOS 14, *) {
				var configuration = cell.defaultContentConfiguration()
				configuration.text = collection.title
				
				// "Moving albums" mode
				if let albumMoverClipboard = albumMoverClipboard {
					if collection.objectID == albumMoverClipboard.idOfCollectionThatAlbumsAreBeingMovedOutOf {
						configuration.textProperties.color = .placeholderText // A proper way to make cells look disabled would be better. This is slightly different from the old cell.textLabel.isEnabled = false.
						cell.selectionStyle = .none
						cell.accessibilityTraits.formUnion(.notEnabled) // should never change
					}
				}
				
				cell.contentConfiguration = configuration
				
			} else { // iOS 13 and earlier
				cell.textLabel?.text = collection.title
				
				// "Moving albums" mode
				if let albumMoverClipboard = albumMoverClipboard {
					if collection.objectID == albumMoverClipboard.idOfCollectionThatAlbumsAreBeingMovedOutOf {
						cell.textLabel?.isEnabled = false
						cell.selectionStyle = .none
						cell.accessibilityTraits.formUnion(.notEnabled) // should never change
					}
				}
			}
			
			// Accessibility
			let renameCollectionAccessibilityCustomAction = UIAccessibilityCustomAction(
				name: "Rename",
				actionHandler: { _ in self.renameAccessibilityFocusedCollection() } )
			cell.accessibilityCustomActions = [renameCollectionAccessibilityCustomAction]
			
			return cell
		}
	}
	
	private func renameAccessibilityFocusedCollection() -> Bool {
		var indexPathOfCollectionToRename: IndexPath?
		let section = 0
		let indexPathsOfAllCollections = tableView.indexPathsEnumeratedIn(
			section: section,
			firstRow: numberOfRowsAboveIndexedLibraryItems)
		for indexPath in indexPathsOfAllCollections {
			if
				let cell = tableView.cellForRow(at: indexPath),
				cell.accessibilityElementIsFocused()
			{
				indexPathOfCollectionToRename = indexPath
				break
			}
		}
		
		if let indexPathOfCollectionToRename = indexPathOfCollectionToRename {
			renameCollection(at: indexPathOfCollectionToRename)
			return true
		} else {
			return false
		}
	}
	
	// MARK: - Editing
	
	override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
		renameCollection(at: indexPath)
	}
	
	// MARK: - Selecting
	
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
	
}
