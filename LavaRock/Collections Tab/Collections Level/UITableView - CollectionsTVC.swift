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
	
	// Remember to call refreshBarButtons() before returning. super also does it.
	final override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if didJustFinishLoading { // This state should only ever happen extremely briefly. You must check for this before checking for isLoading.
			refreshBarButtons()
			tableView.backgroundView = nil
			return 0
		}
		
		if
			MPMediaLibrary.authorizationStatus() != .authorized ||
				isLoading
		{
			refreshBarButtons()
			tableView.backgroundView = nil
			return 1 // "Allow Access" or "Loading…" cell
		}
		
		return super.tableView(tableView, numberOfRowsInSection: section)
	}
	
	// MARK: - Cells
	
	final override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if
			MPMediaLibrary.authorizationStatus() != .authorized ||
				isLoading
		{
			return allowAccessOrLoadingCell()
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
				cell.isUserInteractionEnabled = false
				cell.accessibilityTraits.formUnion(.notEnabled)
			} else { // Undo changes made to the disabled cell
				cell.titleLabel.textColor = UIColor.label
				cell.isUserInteractionEnabled = true
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
	private func allowAccessOrLoadingCell() -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "Allow Access or Loading Cell") as? AllowAccessOrLoadingCell else {
			return UITableViewCell()
		}
		
		if MPMediaLibrary.authorizationStatus() != .authorized {
			// Show "Allow Access" state
			cell.allowAccessOrLoadingLabel.text = LocalizedString.allowAccessToMusic
			cell.allowAccessOrLoadingLabel.textColor = view.window?.tintColor
			cell.spinnerView.stopAnimating()
			cell.isUserInteractionEnabled = true
			cell.accessibilityTraits.formUnion(.button)
			return cell
		} else {
			// We should be importing changes with no existing Collections: isLoading == true
			// Show "Loading…" state
			cell.allowAccessOrLoadingLabel.text = LocalizedString.loadingWithEllipsis
			cell.allowAccessOrLoadingLabel.textColor = .secondaryLabel
			cell.spinnerView.startAnimating()
			cell.isUserInteractionEnabled = false
			cell.accessibilityTraits.remove(.button)
			return cell
		}
	}
	
	// Built-in cell
//	private func allowAccessOrLoadingCell() -> UITableViewCell {
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
	
	// Similar to viewDidLoad().
	private func didReceiveAuthorizationForMusicLibrary() {
		setUp()
		
		isEitherLoadingOrUpdating = true
		tableView.performBatchUpdates {
			let indexPath = IndexPath(row: 0, section: 0)
			tableView.reloadRows(at: [indexPath], with: .fade)
		} completion: { _ in
			self.integrateWithAndImportChangesFromMusicLibraryIfAuthorized()
		}
	}
	
}
