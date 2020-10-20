//
//  UITableView - LibraryTVC.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit
import MediaPlayer

extension LibraryTVC {
	
	// MARK: - Cells
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// You need to accommodate 2 special cases:
		// 1. When the user hasn't allowed access to Apple Music, use the "Allow Access to Apple Music" cell as a button.
		// 2. When there are no items, set the no-content placeholder to the background view.
		refreshBarButtons()
		switch MPMediaLibrary.authorizationStatus() {
		case .authorized:
			// This logic, for setting the "no items" placeholder, should be in numberOfRowsInSection, not in numberOfSections.
			// - If you put it in numberOfSections, VoiceOver moves focus from the tab bar directly to the navigation bar title, skipping over the placeholder. (It will move focus to the placeholder if you tap there, but then you won't be able to move focus out until you tap elsewhere.)
			// - If you put it in numberOfRowsInSection, VoiceOver move focus from the tab bar to the placeholder, then to the navigation bar title, as expected.
			
			if indexedLibraryItems.count > 0 {
				tableView.backgroundView = nil
				return indexedLibraryItems.count + numberOfRowsAboveIndexedLibraryItems
			} else {
				if let noItemsView = tableView.dequeueReusableCell(withIdentifier: "No Items Cell") { // Every subclass needs a placeholder cell in the storyboard with this reuse identifier.
					tableView.backgroundView = noItemsView // As of iOS 14.0 beta 8, this crashes with EXC_BAD_ACCESS (code=2) when rotating from landscape to portrait (and sometimes when rotating from portrait to landscape, depending on your text size). The crash report in iOS Settings says "KERN_PROTECTION_FAILURE".
					// TO DO: I've temporarily disabled landscape. Re-enable it after Apple fixes this.
				}
				return 0
			}
		default:
			tableView.backgroundView = nil
			return 1 // "Allow Access" cell
		}
	}
	
	// All subclasses should override this.
	// Also, all subclasses should check the authorization status for the Apple Music library, and if the user hasn't granted authorization yet, they should call super (this implementation) to return the "Allow Access" cell.
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return allowAccessCell(for: indexPath)
		}
		return UITableViewCell()
	}
	
	private func allowAccessCell(for indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Allow Access Cell", for: indexPath) // We need a copy of this cell in every scene in the storyboard that might use it.
		if #available(iOS 14.0, *) {
			var configuration = UIListContentConfiguration.cell()
			configuration.text = "Allow Access to Apple Music"
			configuration.textProperties.color = view.window?.tintColor ?? UIColor.systemBlue
			cell.contentConfiguration = configuration
		} else { // iOS 13 and earlier
			cell.textLabel?.textColor = view.window?.tintColor
		}
		cell.accessibilityTraits = .button // should never change
		return cell
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
			refreshAccessibilityTraitsAfterDidSelectRow(at: indexPath)
		}
	}
	
	// Easy to override.
	@objc func refreshAccessibilityTraitsAfterDidSelectRow(at indexPath: IndexPath) {
		guard let cell = tableView.cellForRow(at: indexPath) else { return }
		cell.accessibilityTraits = .selected
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
		refreshAccessibilityTraitsAfterDidDeselectRow(at: indexPath)
	}
	
	// Easy to override.
	@objc func refreshAccessibilityTraitsAfterDidDeselectRow(at indexPath: IndexPath) {
		guard let cell = tableView.cellForRow(at: indexPath) else { return }
		cell.accessibilityTraits = .none
	}
	
}
