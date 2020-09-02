//
//  UITableViewDelegate (LibraryTVC).swift
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
					DispatchQueue.main.async { self.didReceiveAuthorizationForAppleMusicLibrary() }
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
	
	private func didReceiveAuthorizationForAppleMusicLibrary() {
		respondsToWillSaveChangesFromAppleMusicLibraryNotifications = false
		mediaPlayerManager.shouldNextMergeBeSynchronous = true
		viewDidLoad() // Includes mediaPlayerManager.setUpLibraryIfAuthorized(), which includes merging changes from the Apple Music library.
		switch tableView(tableView, numberOfRowsInSection: 0) { // tableView.numberOfRows might not be up to date yet. Call the actual UITableViewDelegate method.
		case 0:
			tableView.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
		case 1:
			tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .middle)
		default:
			tableView.performBatchUpdates({
				tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .middle)
				tableView.insertRows(at: indexPathsEnumeratedIn(section: 0, firstRow: 1, lastRow: tableView(tableView, numberOfRowsInSection: 0) - 1), with: .middle)
			}, completion: nil)
		}
		respondsToWillSaveChangesFromAppleMusicLibraryNotifications = true
	}
	
	override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
		refreshNavigationBarButtons()
	}
	
}
