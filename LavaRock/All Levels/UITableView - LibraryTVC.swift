//
//  UITableView - LibraryTVC.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit

extension LibraryTVC {
	
	// MARK: - Numbers
	
	// Subclasses that override this method should call super (this implementation), or remember to call refreshBarButtons().
	override func tableView(
		_ tableView: UITableView,
		numberOfRowsInSection section: Int
	) -> Int {
		refreshBarButtons()
		// Set the "no items" placeholder in numberOfRowsInSection (here), not in numberOfSections.
		// - If you put it in numberOfSections, VoiceOver moves focus from the tab bar directly to the navigation bar title, skipping over the placeholder. (It will move focus to the placeholder if you tap there, but then you won't be able to move focus out until you tap elsewhere.)
		// - If you put it in numberOfRowsInSection, VoiceOver moves focus from the tab bar to the placeholder, then to the navigation bar title, as expected.
		if sectionOfLibraryItems.items.isEmpty {
			// TO DO: Wait until we've removed all the rows before we set the placeholder. Also, animate showing and hiding the placeholder.
			tableView.backgroundView = noItemsPlaceholderView // Don't use dequeueReusableCell to create a placeholder view as needed every time within numberOfRowsInSection (here), because that might call numberOfRowsInSection, which causes an infinite loop.
			return 0
		} else {
			tableView.backgroundView = nil
			return sectionOfLibraryItems.items.count + numberOfRowsInSectionAboveLibraryItems
		}
	}
	
	// MARK: - Cells
	
	// All subclasses should override this.
	override func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		return UITableViewCell()
	}
	
	// MARK: - Editing
	
	final override func tableView(
		_ tableView: UITableView,
		canEditRowAt indexPath: IndexPath
	) -> Bool {
		return indexPath.row >= numberOfRowsInSectionAboveLibraryItems
	}
	
	// MARK: Rearranging
	
	final override func tableView(
		_ tableView: UITableView,
		moveRowAt fromIndexPath: IndexPath,
		to: IndexPath
	) {
		let fromItemIndex = indexOfLibraryItem(for: fromIndexPath)
		let toItemIndex = indexOfLibraryItem(for: to)
		
		let itemBeingMoved = sectionOfLibraryItems.items[fromItemIndex]
		var newItems = sectionOfLibraryItems.items
		newItems.remove(at: fromItemIndex)
		newItems.insert(itemBeingMoved, at: toItemIndex)
		sectionOfLibraryItems.setItems(newItems)
		
		refreshBarButtons() // If you made selected items non-contiguous, that should disable the Sort button. If you made selected items contiguous, that should enable the Sort button.
	}
	
	final override func tableView(
		_ tableView: UITableView,
		targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
		toProposedIndexPath proposedDestinationIndexPath: IndexPath
	) -> IndexPath {
		if proposedDestinationIndexPath.row < numberOfRowsInSectionAboveLibraryItems {
			return indexPathFor(
				indexOfLibraryItem: 0,
				indexOfSectionOfLibraryItem: proposedDestinationIndexPath.section)
		} else {
			return proposedDestinationIndexPath
		}
	}
	
	// MARK: - Selecting
	
//	final override func tableView(
//		_ tableView: UITableView,
//		shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath
//	) -> Bool {
//		return true
//	}
//
//	final override func tableView(
//		_ tableView: UITableView,
//		didBeginMultipleSelectionInteractionAt indexPath: IndexPath
//	) {
//		print("")
//		print("Began multiple-selection interaction at IndexPath: \(indexPath)")
//		setEditing(true, animated: true)
//	}
//
//	override func tableViewDidEndMultipleSelectionInteraction(_ tableView: UITableView) {
//		print("Ended multiple-selection interaction.")
//	}
	
	// Subclasses that override this method must call super (this implementation).
	override func tableView(
		_ tableView: UITableView,
		didSelectRowAt indexPath: IndexPath
	) {
		if isEditing {
			refreshBarButtons()
			if let cell = tableView.cellForRow(at: indexPath) {
				cell.accessibilityTraits.formUnion(.selected)
			}
		}
	}
	
	// MARK: Deselecting
	
	final override func tableView(
		_ tableView: UITableView,
		didDeselectRowAt indexPath: IndexPath
	) {
		refreshBarButtons()
		if let cell = tableView.cellForRow(at: indexPath) {
			cell.accessibilityTraits.subtract(.selected)
		}
	}
	
}
