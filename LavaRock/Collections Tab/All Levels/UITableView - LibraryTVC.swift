//
//  UITableView - LibraryTVC.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit
import MediaPlayer

extension LibraryTVC {
	
	// MARK: - Numbers
	
	final override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		refreshBarButtons()
		switch MPMediaLibrary.authorizationStatus() {
		case .authorized:
			// Set the "no items" placeholder in numberOfRowsInSection (here), not in numberOfSections.
			// - If you put it in numberOfSections, VoiceOver moves focus from the tab bar directly to the navigation bar title, skipping over the placeholder. (It will move focus to the placeholder if you tap there, but then you won't be able to move focus out until you tap elsewhere.)
			// - If you put it in numberOfRowsInSection, VoiceOver move focus from the tab bar to the placeholder, then to the navigation bar title, as expected.
			let numberOfLibraryItems = indexedLibraryItems.count
			switch numberOfLibraryItems {
			case 0:
				// TO DO: Wait until we've removed all the rows before we set the placeholder. Also, animate showing and hiding the placeholder.
				tableView.backgroundView = noItemsPlaceholderView // Don't use dequeueReusableCell to create a placeholder view as needed every time within numberOfRowsInSection (here), because that might call numberOfRowsInSection, which causes an infinite loop.
				return numberOfLibraryItems
			default:
				tableView.backgroundView = nil
				return numberOfLibraryItems + numberOfRowsAboveIndexedLibraryItems
			}
		default: // We haven't asked to access Music yet, or the user has denied permission.
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
	
	final override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return indexPath.row >= numberOfRowsAboveIndexedLibraryItems
	}
	
	// MARK: Rearranging
	
	final override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
		let fromIndex = fromIndexPath.row - numberOfRowsAboveIndexedLibraryItems
		let toIndex = to.row - numberOfRowsAboveIndexedLibraryItems
		
		let itemBeingMoved = indexedLibraryItems[fromIndex]
		indexedLibraryItems.remove(at: fromIndex)
		indexedLibraryItems.insert(itemBeingMoved, at: toIndex)
		refreshBarButtons() // If you made selected items non-contiguous, that should disable the Sort button. If you made selected items contiguous, that should enable the Sort button.
	}
	
	final override func tableView(
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
	
	// Subclasses that override this method should call super (this implementation), or make sure to accommodate numberOfRowsAboveIndexedLibraryItems.
	override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
		if indexPath.row < numberOfRowsAboveIndexedLibraryItems {
			return nil
		} else {
			return indexPath
		}
	}
	
	// Subclasses that override this method must call super (this implementation).
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if isEditing {
			refreshBarButtons()
			if let cell = tableView.cellForRow(at: indexPath) {
				cell.accessibilityTraits.formUnion(.selected)
			}
		}
	}
	
	// MARK: Deselecting
	
	final override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
		refreshBarButtons()
		if let cell = tableView.cellForRow(at: indexPath) {
			cell.accessibilityTraits.subtract(.selected)
		}
	}
	
}
