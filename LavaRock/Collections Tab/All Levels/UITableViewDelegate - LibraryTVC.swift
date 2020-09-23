//
//  UITableViewDelegate - LibraryTVC.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit
import MediaPlayer

extension LibraryTVC {
	
	// MARK: - Rearranging
	
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
			MPMediaLibrary.requestAuthorization() { newStatus in // Fires the alert asking the user for access.
				switch newStatus {
				case .authorized:
					DispatchQueue.main.async { self.didReceiveAuthorizationForAppleMusic() }
				default:
					DispatchQueue.main.async { self.tableView.deselectRow(at: indexPath, animated: true) }
				}
			}
		default: // Denied or restricted.
			let settingsURL = URL(string: UIApplication.openSettingsURLString)!
			UIApplication.shared.open(settingsURL)
			tableView.deselectRow(at: indexPath, animated: true)
		}
		
		if isEditing {
			refreshBarButtons()
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
	}
	
}
