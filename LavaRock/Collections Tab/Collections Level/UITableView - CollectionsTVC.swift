//
//  UITableView - CollectionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit
import MediaPlayer

extension CollectionsTVC {
	
	// MARK: - Numbers
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if isImportingMusicLibraryForTheFirstTime {
			return 1
		}
		
		return super.tableView(tableView, numberOfRowsInSection: section)
	}
	
	// MARK: - Cells
	
	final override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return allowAccessCell()
		}
		
		if
			isImportingMusicLibraryForTheFirstTime,
			indexedLibraryItems.isEmpty
		{
			let cell = tableView.dequeueReusableCell(withIdentifier: "Loading Cell", for: indexPath)
			return cell
		}
		
		if indexPath.row < numberOfRowsAboveIndexedLibraryItems {
			return UITableViewCell()
		} else { // Return a cell for an item in indexedLibraryItems.
			return collectionCell(forRowAt: indexPath)
		}
	}
	
	private func collectionCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		// Get the data to put into the cell.
		let collection = indexedLibraryItems[indexPath.row - numberOfRowsAboveIndexedLibraryItems] as! Collection
		
		// Make, configure, and return the cell.
		
		guard var cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as? CollectionCell else {
			return UITableViewCell()
		}
		
		cell.titleLabel.text = collection.title
		let isNowPlayingCollection = isItemNowPlaying(at: indexPath)
		let cellNowPlayingIndicator = PlayerControllerManager.nowPlayingIndicator(
			isItemNowPlaying: isNowPlayingCollection)
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
		
		let renameCollectionAccessibilityCustomAction = UIAccessibilityCustomAction(
			name: LocalizedString.rename,
			actionHandler: { _ in self.renameAccessibilityFocusedCollection() } )
		cell.accessibilityCustomActions = [renameCollectionAccessibilityCustomAction]
//		refreshVoiceControlNames(for: cell)
		
		return cell
	}
	
//	final func refreshVoiceControlNames(for cell: UITableViewCell) {
//		if isEditing {
//			cell.accessoryView?.accessibilityUserInputLabels = ["Info", "Detail", "Rename"] // I want to give the "rename collection" button a name for Voice Control, but this line of code doesn't do it.
//		} else {
//			cell.accessoryView?.accessibilityUserInputLabels = [""]
//		}
//	}
	
	private func renameAccessibilityFocusedCollection() -> Bool {
		var indexPathOfCollectionToRename: IndexPath?
		let section = 0
		let indexPathsOfAllCollections = tableView.indexPathsForRowsIn(
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
	private func allowAccessCell() -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "Allow Access Cell") as? AllowAccessCell else {
			return UITableViewCell()
		}
		cell.label.textColor = view.window?.tintColor
		return cell
	}
	
	// Built-in cell
//	private func allowAccessCell() -> UITableViewCell {
//		let cell = tableView.dequeueReusableCell(withIdentifier: "Allow Access Cell")
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
	
	final override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
		renameCollection(at: indexPath)
	}
	
	// MARK: - Selecting
	
	final override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
		if let albumMoverClipboard = albumMoverClipboard {
			let collectionID = indexedLibraryItems[indexPath.row - numberOfRowsAboveIndexedLibraryItems].objectID
			if collectionID == albumMoverClipboard.idOfCollectionThatAlbumsAreBeingMovedOutOf {
				return nil
			}
		}
		
		return super.tableView(tableView, willSelectRowAt: indexPath)
	}
	
	final override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		switch MPMediaLibrary.authorizationStatus() {
		case .authorized:
			break
		case .notDetermined: // The golden opportunity.
			MPMediaLibrary.requestAuthorization { newStatus in
				switch newStatus {
				case .authorized:
					DispatchQueue.main.async { self.didReceiveAuthorizationForMusicLibrary() }
				default:
					DispatchQueue.main.async { self.tableView.deselectRow(at: indexPath, animated: true) }
				}
			}
		default: // Denied or restricted.
			if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
				UIApplication.shared.open(settingsURL)
			}
			tableView.deselectRow(at: indexPath, animated: true)
		}
		
		super.tableView(tableView, didSelectRowAt: indexPath) // Includes refreshBarButtons() in editing mode.
	}
	
	private func didReceiveAuthorizationForMusicLibrary() {
		// Put the UI into the "Loading…" state, then continue in part 2.
		
		isImportingMusicLibraryForTheFirstTime = true // TO DO: Move the source of truth for this to the change-importer.
		
		// Replace Edit button with spinner
//		refreshAndSetBarButtons(animated: false)
		
		tableView.performBatchUpdates {
			tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .fade) // Note: We have to wait for the animation to complete before we can start the change-importer (on the main thread), but that wastes time, of course.
		} completion: { _ in
			self.didReceiveAuthorizationForMusicLibraryPart2()
		}
	}
	
	private func didReceiveAuthorizationForMusicLibraryPart2() {
		refreshesAfterDidSaveChangesFromMusicLibrary = false // Supress our usual refresh after observing the LRDidSaveChangesFromMusicLibrary notification that we'll post after importing changes; in this case, we'll update the UI in a different way, below.
		integrateWithAndImportChangesFromMusicLibraryIfAuthorized() // Do this before setUp(), because when we call setUp(), we need to already have integrated with and imported changes from the Music library.
		setUp() // Includes refreshing the playback toolbar.
		
		// Take the UI out of the "Loading…" state.
		
		isImportingMusicLibraryForTheFirstTime = false // TO DO: Move the source of truth for this to the change-importer.
		
		// Revert spinner back to Edit button
//		refreshAndSetBarButtons(animated: false) // It should be safe to do this before updating the table view (instead of having to wait for completion), because we've already completed the import and reloaded indexedLibraryItems.
		
		let newNumberOfRows = tableView(tableView, numberOfRowsInSection: 0)
		tableView.performBatchUpdates {
			tableView.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
			tableView.insertRows(
				at: tableView.indexPathsForRowsIn(
					section: 0,
					firstRow: 0,
					lastRow: newNumberOfRows - 1), // It's incorrect and unsafe to call tableView.numberOfRows(inSection:) here, because we're changing the number of rows. Use the UITableViewDelegate method tableView(_:numberOfRowsInSection:) intead.
				with: .middle)
		} completion: { _ in
			self.refreshesAfterDidSaveChangesFromMusicLibrary = true
		}
	}
	
}
