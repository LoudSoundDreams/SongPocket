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
			return allowAccessCell(for: indexPath)
		}
		
		if indexPath.row < numberOfRowsAboveIndexedLibraryItems {
			
			return UITableViewCell()
			
		} else { // Return a cell for an item in indexedLibraryItems.
			// Get the data to put into the cell.
			let collection = indexedLibraryItems[indexPath.row - numberOfRowsAboveIndexedLibraryItems] as! Collection
			
			// Make, configure, and return the cell.
			
			
			// Custom cell
			
			var cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! CollectionCell
			
			cell.titleLabel.text = collection.title
			let isNowPlayingCollection = isNowPlayingItem(at: indexPath)
			let cellNowPlayingIndicator = nowPlayingIndicator(isNowPlayingItem: isNowPlayingCollection)
			cell.applyNowPlayingIndicator(cellNowPlayingIndicator)
			
			// "Moving Albums" mode
			if let albumMoverClipboard = albumMoverClipboard {
				if collection.objectID == albumMoverClipboard.idOfCollectionThatAlbumsAreBeingMovedOutOf {
					cell.titleLabel.textColor = UIColor.placeholderText // A proper way to make cells look disabled would be better. This is slightly different from the old cell.textLabel.isEnabled = false.
					cell.selectionStyle = .none
					cell.accessibilityTraits.formUnion(.notEnabled)
				} else { // Undo changes made to the disabled cell
					cell.titleLabel.textColor = UIColor.label
					cell.selectionStyle = .default
					cell.accessibilityTraits.remove(.notEnabled)
				}
			}
			
			
			/*
			// Built-in cell
			
			let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
			if #available(iOS 14, *) {
				var configuration = cell.defaultContentConfiguration()
				configuration.text = collection.title
				
				// "Moving Albums" mode
				if let albumMoverClipboard = albumMoverClipboard {
					if collection.objectID == albumMoverClipboard.idOfCollectionThatAlbumsAreBeingMovedOutOf {
						configuration.textProperties.color = .placeholderText // A proper way to make cells look disabled would be better. This is slightly different from the old cell.textLabel.isEnabled = false.
						cell.selectionStyle = .none
						cell.accessibilityTraits.formUnion(.notEnabled)
					} else { // Undo changes made to the disabled cell
						configuration.textProperties.color = .label
						cell.selectionStyle = .default
						cell.accessibilityTraits.remove(.notEnabled)
					}
				}
				
				cell.contentConfiguration = configuration
				
			} else { // iOS 13 and earlier
				cell.textLabel?.text = collection.title
				
				// "Moving Albums" mode
				if let albumMoverClipboard = albumMoverClipboard {
					if collection.objectID == albumMoverClipboard.idOfCollectionThatAlbumsAreBeingMovedOutOf {
						cell.textLabel?.isEnabled = false
						cell.selectionStyle = .none
						cell.accessibilityTraits.formUnion(.notEnabled)
					} else { // Undo changes made to the disabled cell
						cell.textLabel?.isEnabled = true
						cell.selectionStyle = .default
						cell.accessibilityTraits.remove(.notEnabled)
					}
				}
			}
			*/
			
			let renameCollectionAccessibilityCustomAction = UIAccessibilityCustomAction(
				name: LocalizedString.rename,
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
	
	// MARK: "Allow Access" Cell
	
	// Custom cell
	private func allowAccessCell(for indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "Allow Access Cell", for: indexPath) as? AllowAccessCell else {
			return UITableViewCell()
		}
		
		cell.label.textColor = view.window?.tintColor
		cell.accessibilityTraits.formUnion(.button) // should never change
		
		return cell
	}
	
	// Built-in cell
//	private func allowAccessCell(for indexPath: IndexPath) -> UITableViewCell {
//		let cell = tableView.dequeueReusableCell(withIdentifier: "Allow Access Cell", for: indexPath)
//		if #available(iOS 14.0, *) {
//			var configuration = UIListContentConfiguration.cell()
//			configuration.text = "Allow Access to Music"
//			configuration.textProperties.color = view.window?.tintColor ?? UIColor.systemBlue
//			cell.contentConfiguration = configuration
//		} else { // iOS 13 and earlier
//			cell.textLabel?.textColor = view.window?.tintColor
//		}
//		cell.accessibilityTraits.formUnion(.button) // should never change
//		return cell
//	}
	
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
