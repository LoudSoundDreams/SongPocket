//
//  LibraryTVC - UITableView.swift
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
		if sectionOfLibraryItems.isEmpty() {
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
	
	// MARK: Reordering
	
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
		
		refreshBarButtons() // If you made selected items non-contiguous, that should disable the "Sort" button. If you made selected items contiguous, that should enable the "Sort" button.
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
	
	// Subclasses that override this method must call super (this implementation).
	override func tableView(
		_ tableView: UITableView,
		shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath
	) -> Bool {
		guard indexPath.row >= numberOfRowsInSectionAboveLibraryItems else {
			return false
		}
		return true
	}

	final override func tableView(
		_ tableView: UITableView,
		didBeginMultipleSelectionInteractionAt indexPath: IndexPath
	) {
		if !isEditing {
			setEditing(true, animated: true) // As of iOS 14.7 beta 2, with LavaRock's codebase as of build 144, starting a multiple-selection interaction sometimes causes the table view to crash when our override of setEditing calls tableView.performBatchUpdates(nil), with "[Assert] Attempted to call -cellForRowAtIndexPath: on the table view while it was in the process of updating its visible cells, which is not allowed."
			// During WWDC 2021, I did a lab in UIKit where the Apple engineer was pretty sure that this was a bug in UITableView.
			// By checking isEditing first, we either prevent that or make it very rare.
		}
	}
	
	// To disable selection for a row, it's simpler to set cell.isUserInteractionEnabled = false.
	// However, you can select a multiple-selection interaction on a cell that does allow user interaction, and swipe over a cell that doesn't allow user interaction, to select it too.
	// Therefore, with multiple-selection interactions, you must use this method to disable selection for certain rows.
	final override func tableView(
		_ tableView: UITableView,
		willSelectRowAt indexPath: IndexPath
	) -> IndexPath? {
		guard indexPath.row >= numberOfRowsInSectionAboveLibraryItems else {
			return nil
		}
		return indexPath
	}
	
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
