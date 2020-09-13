//
//  UITableViewDelegate - LibraryTVC.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit
import MediaPlayer

extension LibraryTVC {
	
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
			refreshNavigationBarButtons()
		}
		
	}
	
	private func didReceiveAuthorizationForAppleMusic() {
		refreshesAfterDidSaveChangesFromAppleMusic = false
		AppleMusicLibraryManager.shared.shouldNextMergeBeSynchronous = true
		viewDidLoad() // Includes AppleMusicLibraryManager's setUpLibraryIfAuthorized(), which includes merging changes from the Apple Music library. Since we set shouldNextMergeBeSynchronous = true, CollectionsTVC will call the (synchronous) merge before reloadIndexedLibraryItems(), to make sure that indexedLibraryItems is ready for the following.
		// Remove the following and make refreshDataAndViewsWhenVisible() accomodate it instead?
		switch tableView(tableView, numberOfRowsInSection: 0) { // tableView.numberOfRows might not be up to date yet. Call the actual UITableViewDelegate method.
		case 0:
			tableView.performBatchUpdates {
				tableView.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
			} completion: { _ in
				self.refreshesAfterDidSaveChangesFromAppleMusic = true
			}
		case 1:
			tableView.performBatchUpdates {
				tableView.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
				tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .middle)
			} completion: { _ in
				self.refreshesAfterDidSaveChangesFromAppleMusic = true
			}
		default:
			tableView.performBatchUpdates({
				tableView.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
				tableView.insertRows(at: indexPathsEnumeratedIn(section: 0, firstRow: 0, lastRow: tableView(tableView, numberOfRowsInSection: 0) - 1), with: .middle)
			}, completion: { _ in
				self.refreshesAfterDidSaveChangesFromAppleMusic = true
			})
		}
	}
	
	override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
		refreshNavigationBarButtons()
	}
	
}
