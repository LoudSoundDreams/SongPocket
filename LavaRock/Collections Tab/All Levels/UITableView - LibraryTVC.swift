//
//  UITableView - LibraryTVC.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit
import MediaPlayer

extension LibraryTVC {
	
	// MARK: - Rows
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		refreshBarButtons()
		switch MPMediaLibrary.authorizationStatus() {
		case .authorized:
			// Set the "no items" placeholder in numberOfRowsInSection (here), not in numberOfSections.
			// - If you put it in numberOfSections, VoiceOver moves focus from the tab bar directly to the navigation bar title, skipping over the placeholder. (It will move focus to the placeholder if you tap there, but then you won't be able to move focus out until you tap elsewhere.)
			// - If you put it in numberOfRowsInSection, VoiceOver move focus from the tab bar to the placeholder, then to the navigation bar title, as expected.
			let numberOfLibraryItems = indexedLibraryItems.count
			switch numberOfLibraryItems {
			case 0:
				tableView.backgroundView = noItemsPlaceholderView // Don't use dequeueReusableCell to create a placeholder view as needed every time within numberOfRowsInSection (here), because that might call numberOfRowsInSection, which causes an infinite loop.
				return numberOfLibraryItems
			default:
				tableView.backgroundView = nil
				return numberOfLibraryItems + numberOfRowsAboveIndexedLibraryItems
			}
		default: // We haven't asked to access Apple Music, or the user has denied permission.
			tableView.backgroundView = nil
			return 1 // "allow access" cell
		}
	}
	
	// MARK: Cells
	
	// All subclasses should override this.
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return UITableViewCell()
	}
	
	// MARK: - Editing
	
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return indexPath.row >= numberOfRowsAboveIndexedLibraryItems
	}
	
	// MARK: Rearranging
	
	override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
		let fromIndex = fromIndexPath.row - numberOfRowsAboveIndexedLibraryItems
		let toIndex = to.row - numberOfRowsAboveIndexedLibraryItems
		
		let itemBeingMoved = indexedLibraryItems[fromIndex]
		indexedLibraryItems.remove(at: fromIndex)
		indexedLibraryItems.insert(itemBeingMoved, at: toIndex)
		refreshBarButtons() // If you made selected items non-contiguous, that should disable the Sort button. If you made selected items contiguous, that should enable the Sort button.
	}
	
	override func tableView(
		_ tableView: UITableView,
		targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
		toProposedIndexPath proposedDestinationIndexPath: IndexPath
	) -> IndexPath {
		if proposedDestinationIndexPath.row < numberOfRowsAboveIndexedLibraryItems {
			return IndexPath(
				row: numberOfRowsAboveIndexedLibraryItems,
				section: proposedDestinationIndexPath.section
			)
		} else {
			return proposedDestinationIndexPath
		}
	}
	
	// MARK: - Selecting
	
	override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
		if indexPath.row < numberOfRowsAboveIndexedLibraryItems {
			return nil
		} else {
			return indexPath
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		switch MPMediaLibrary.authorizationStatus() {
		case .authorized:
			break
		case .notDetermined: // The golden opportunity.
			MPMediaLibrary.requestAuthorization { newStatus in
				switch newStatus {
				case .authorized:
					DispatchQueue.main.async { self.didReceiveAuthorizationForAppleMusic() }
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
		
		if isEditing {
			refreshBarButtons()
			if let cell = tableView.cellForRow(at: indexPath) {
				cell.accessibilityTraits.formUnion(.selected)
			}
		}
	}
	
	final func didReceiveAuthorizationForAppleMusic() {
		refreshesAfterDidSaveChangesFromAppleMusic = false
		AppleMusicLibraryManager.shared.shouldNextImportBeSynchronous = true
		viewDidLoad() // Includes AppleMusicLibraryManager's setUpLibraryIfAuthorized(), which includes importing changes from the Apple Music library. Since we set shouldNextImportBeSynchronous = true, CollectionsTVC will call the (synchronous) import before reloadIndexedLibraryItems(), to make sure that indexedLibraryItems is ready for the following.
		
		// Remove the following and make refreshDataAndViewsWhenVisible() accomodate it instead?
		let newNumberOfRows = tableView(tableView, numberOfRowsInSection: 0)
		tableView.performBatchUpdates {
			tableView.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
			tableView.insertRows(
				at: tableView.indexPathsEnumeratedIn(
					section: 0,
					firstRow: 0,
					lastRow: newNumberOfRows - 1), // It's incorrect and unsafe to call tableView.numberOfRows(inSection:) here, because we're changing the number of rows. Use the UITableViewDelegate method tableView(_:numberOfRowsInSection:) intead.
				with: .middle)
		} completion: { _ in
			self.refreshesAfterDidSaveChangesFromAppleMusic = true
		}
	}
	
	// MARK: Deselecting
	
	override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
		refreshBarButtons()
		if let cell = tableView.cellForRow(at: indexPath) {
			cell.accessibilityTraits.subtract(.selected)
		}
	}
	
}
