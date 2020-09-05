//
//  UITableViewDataSource (LibraryTVC).swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit
import MediaPlayer

extension LibraryTVC {
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// You need to accommodate 2 special cases:
		// 1. When the user hasn't allowed access to Apple Music, use the "Allow Access to Apple Music" cell as a button.
		// 2. When there are no items, set the "Add some songs to the Apple Music app." placeholder cell to the background view.
		refreshNavigationBarButtons()
		switch MPMediaLibrary.authorizationStatus() {
		case .authorized:
			// This logic, for setting the "no items" placeholder, should be in numberOfRowsInSection, not in numberOfSections.
			// - If you put it in numberOfSections, VoiceOver moves focus from the tab bar directly to the navigation bar title, skipping over the placeholder. (It will move focus to the placeholder if you tap there, but then you won't be able to move focus out until you tap elsewhere.)
			// - If you put it in numberOfRowsInSection, VoiceOver move focus from the tab bar to the placeholder, then to the navigation bar title, as expected.
			
//			guard let numberOfItems = fetchedResultsController?.sections?[section].numberOfObjects else {
//				return 0
//			}
			
//			if numberOfItems > 0 {
			if activeLibraryItems.count > 0 {
				tableView.backgroundView = nil
//				return numberOfItems
				return activeLibraryItems.count
			} else {
				let noItemsView = tableView.dequeueReusableCell(withIdentifier: "No Items Cell")! // Every subclass needs a placeholder cell in the storyboard with this reuse identifier.
				tableView.backgroundView = noItemsView
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
		return cell
	}
	
	// MARK: - Rearranging
	
	override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
		let itemBeingMoved = activeLibraryItems[fromIndexPath.row]
		// You can replace this with swapAt(_:_:).
		activeLibraryItems.remove(at: fromIndexPath.row)
		activeLibraryItems.insert(itemBeingMoved, at: to.row)
		
		/*
		// Begin NSFetchedResultsController-based implementation.
		
		guard
		fromIndexPath != to,
		fromIndexPath.section == to.section
		else { return }
		
		isUserCurrentlyMovingRowManually = true
		
		// If you intersperse fetchedResultsController.object(at: indexPath) with edits to managed objects, you'll mess up the indexes of the objects while you're trying to get the objects. Therefore, you should get all the objects you need at once, then edit them all at once.
		
		let itemThatTheUserIsMoving = fetchedResultsController!.object(at: fromIndexPath)
		var itemsThatWillBeDisplaced = [NSManagedObject]()
		let isUserMovingRowDownward = fromIndexPath < to
		if isUserMovingRowDownward { // If the user is moving a row downward.
		for indexPath in indexPathsEnumeratedIn(section: to.section, firstRow: fromIndexPath.row, lastRow: to.row) {
		itemsThatWillBeDisplaced.append(fetchedResultsController!.object(at: indexPath))
		}
		for item in itemsThatWillBeDisplaced {
		let oldIndex = item.value(forKey: "index") as! Int
		item.setValue(oldIndex - 1, forKey: "index")
		print("Displaced \(item) from row \(oldIndex) to row \(String(describing: item.value(forKey: "index"))).")
		}
		} else { // The user is moving a row upward.
		for indexPath in indexPathsEnumeratedIn(section: to.section, firstRow: to.row, lastRow: fromIndexPath.row) {
		itemsThatWillBeDisplaced.append(fetchedResultsController!.object(at: indexPath))
		}
		for item in itemsThatWillBeDisplaced {
		let oldIndex = item.value(forKey: "index") as! Int
		item.setValue(oldIndex + 1, forKey: "index")
		print("Displaced \(item) from row \(oldIndex) to row \(String(describing: item.value(forKey: "index"))).")
		}
		}
		itemThatTheUserIsMoving.setValue(to.row, forKey: "index")
		print("Moved \(itemThatTheUserIsMoving) to row \(String(describing: itemThatTheUserIsMoving.value(forKey: "index"))).")
		
		isUserCurrentlyMovingRowManually = false
		
		// End NSFetchedResultsController-based implementation.
		*/
		
		refreshNavigationBarButtons() // If you made selected items non-contiguous, that should disable the Sort button. If you made selected items contiguous, that should enable the Sort button.
	}
	
}
