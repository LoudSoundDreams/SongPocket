//
//  LibraryTableViewController.swift
//  LavaRock
//
//  Created by h on 2020-04-15.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import SwiftUI
import CoreData

class LibraryTableViewController: UITableViewController {
	
	// Properties that subclasses should customize:
	var coreDataEntityName = "Collection"
	
	// Properties that subclasses can optionally customize:
	var barButtonItemsEditMode = [UIBarButtonItem]()
	var sortOptions = ["Title"] // Only include the options you want. Make sure they're spelled right, or they won't do anything.
	
	// Properties that subclasses should not change:
	let tintColor = UIColor(named: "AccentColor")
	let cellReuseIdentifier = "Cell"
	lazy var floatToTopButton = UIBarButtonItem(
		image: UIImage(systemName: "arrow.up.to.line.alt"), // Needs VoiceOver hint
		style: .plain,
		target: self,
		action: #selector(moveSelectedItemsToTop)
	)
	lazy var sortButton = UIBarButtonItem(
		image: UIImage(systemName: "arrow.up.arrow.down"), // Needs VoiceOver hint
		style: .plain,
		target: self,
		action: #selector(showSortOptions)
	)
	lazy var collectionsNC = navigationController as! CollectionsNC
	
	var activeLibraryItems = [NSManagedObject]() { // The truth for the order of items is their order in activeLibraryItems, because the table view follows activeLibraryItems; not the "index" attribute of each NSManagedObject.
		didSet {
			didSetActiveLibraryItems()
		}
	}
	lazy var coreDataFetchRequest: NSFetchRequest<NSManagedObject> = {
		let request = NSFetchRequest<NSManagedObject>(entityName: coreDataEntityName)
		request.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		return request
	}()
	var containerOfData: NSManagedObject?
	
	// MARK: Property Observers
	
	func didSetActiveLibraryItems() {
		for index in 0..<self.activeLibraryItems.count {
			activeLibraryItems[index].setValue(index, forKey: "index")
		}
	}
	
	// MARK: Setup
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setUpUI()
		loadActiveLibraryItems()
	}
	
	// MARK: Setting Up UI
	
	func setUpUI() {
		
		// Always
		
		if containerOfData != nil {
			title = containerOfData?.value(forKey: "title") as? String
		}
		barButtonItemsEditMode = [floatToTopButton]
		tableView.tableFooterView = UIView() // Removes the blank cells after the content ends. You can also drag in an empty View below the table view in the storyboard, but that also removes the separator below the last cell.
		
		// Depending whether the view is in "move albums" mode
		
		if collectionsNC.isInMoveAlbumsMode {
			navigationItem.prompt = collectionsNC.moveAlbumsModePrompt
			navigationItem.rightBarButtonItem = UIBarButtonItem(
				barButtonSystemItem: .cancel,
				target: self,
				action: #selector(cancelMoveAlbums)
			)
			
			navigationController?.isToolbarHidden = false
			
		} else {
			navigationItem.rightBarButtonItem = editButtonItem
			
			navigationController?.isToolbarHidden = true
		}
		
	}
	
	// MARK: Loading Data
	
	func loadActiveLibraryItems() {
		if containerOfData != nil {
			coreDataFetchRequest.predicate = NSPredicate(format: "container == %@", containerOfData!)
		}
		
		activeLibraryItems = collectionsNC.coreDataManager.managedObjects(for: coreDataFetchRequest)
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return activeLibraryItems.count
    }
	
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		// Get the data to put into the cell.
		
		let libraryItem = activeLibraryItems[indexPath.row]
		let itemTitle = libraryItem.value(forKey: "title") as? String
		
		// Make, configure, and return the cell.
		
		let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
		
		if #available(iOS 14, *) {
			
			var configuration = cell.defaultContentConfiguration()
			
			configuration.text = itemTitle
			
			cell.contentConfiguration = configuration
			
		} else { // iOS 13 and earlier
			
			cell.textLabel?.text = itemTitle
			
		}
		
        return cell
		
    }
	
	// MARK: Events
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		if isEditing {
			collectionsNC.coreDataManager.save()
		}
		
		super.setEditing(editing, animated: animated)
		
		updateBarButtonItems()
		
		// Makes the cells resize themselves (expand if text has wrapped around to new lines; shrink if text has unwrapped into fewer lines).
		// Otherwise, they'll stay the same size until they reload some other time, like after you edit them or they leave memory.
		tableView.performBatchUpdates(nil, completion: nil) // As of iOS 14.0 beta 3, this causes the app to sometimes crash with an NSRangeException later on after moving a row. beginUpdates() and endUpdates() causes the same.
		// NOTE: Apparently only when Dynamic Text size is one size larger than default, and 13 particular collections exist. Sometimes the crash is NSInternalInconsistencyException.
	}
	
	func updateBarButtonItems() {
		if isEditing {
			floatToTopButton.isEnabled = shouldAllowFloatingToTop()
			sortButton.isEnabled = shouldAllowSorting()
			navigationItem.setLeftBarButtonItems(barButtonItemsEditMode, animated: true)
		} else {
			navigationItem.setLeftBarButtonItems(nil, animated: true)
		}
	}
	
	@objc func cancelMoveAlbums() {
		dismiss(animated: true, completion: nil)
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if isEditing {
			updateBarButtonItems()
		}
	}
	
	override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
		updateBarButtonItems()
	}
	
	override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
		return !isEditing
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "Drill Down in Library",
			let destination = segue.destination as? LibraryTableViewController,
			tableView.indexPathForSelectedRow != nil {
			let selectedItem = activeLibraryItems[tableView.indexPathForSelectedRow!.row]
			destination.containerOfData = selectedItem
		}
	}
	
//	@IBSegueAction func drillDownInLibrarySwiftUI(_ coder: NSCoder) -> UIViewController? {
//		let selectedItem = activeLibraryItems[tableView.indexPathForSelectedRow!.row]
//		let selectedItemTitle = selectedItem.value(forKey: "title") as! String
//		let destination = UIHostingController(coder: coder, rootView: SongsView())
//		// As of iOS 13.5.1, if you set .navigationBarTitle within SongsView, it doesn't animate in; it just appears after the show segue finishes.
//		destination?.navigationItem.title = selectedItemTitle
//		return destination
//	}
	
	// MARK: Rearranging
	
	override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
		let itemBeingMoved = activeLibraryItems[fromIndexPath.row]
		activeLibraryItems.remove(at: fromIndexPath.row)
		activeLibraryItems.insert(itemBeingMoved, at: to.row)
		updateBarButtonItems() // If you made selected items non-consecutive, that should disable the Sort button. If you made selected items consecutive, that should enable the Sort button.
	}
	
	// MARK: Moving Rows to Top
	
	@objc func moveSelectedItemsToTop() {
		moveItemsUp(from: tableView.indexPathsForSelectedRows, to: IndexPath(row: 0, section: 0))
	}
	
	// NOTE: Every IndexPath in selectedIndexPaths must be in the same section as targetIndexPath, and at or down below targetIndexPath.
	func moveItemsUp(from indexPaths: [IndexPath]?, to targetIndexPath: IndexPath) {
		
		guard let selectedIndexPaths = indexPaths else {
			return
		}
		for indexPath in selectedIndexPaths {
			if indexPath.section != targetIndexPath.section || indexPath.row < targetIndexPath.row {
				return
			}
		}
		
		let indexPathsAndItems = dataObjectsPairedWith(selectedIndexPaths.sorted(), tableViewDataSource: activeLibraryItems) as! [(IndexPath, NSManagedObject)]
		var rowToMoveTo = targetIndexPath.row
		for indexPathAndItem in indexPathsAndItems {
			tableView.moveRow(at: indexPathAndItem.0, to: IndexPath(row: rowToMoveTo, section: targetIndexPath.section))
			activeLibraryItems.remove(at: indexPathAndItem.0.row)
			activeLibraryItems.insert(indexPathAndItem.1, at: rowToMoveTo)
			tableView.deselectRow(at: IndexPath(row: rowToMoveTo, section: targetIndexPath.section), animated: true) // Wait until after all the rows have moved to do this?
			rowToMoveTo += 1
		}
		updateBarButtonItems()
	}
	
	// MARK: Sorting
	
	// Unfortunately, we can't save UIAlertActions as constant properties of LibraryTableViewController. They're view controllers.
	@objc func showSortOptions() {
		let alertController = UIAlertController(title: "Sort By", message: nil, preferredStyle: .actionSheet)
		alertController.view.tintColor = tintColor
		for sortOption in sortOptions {
			alertController.addAction(UIAlertAction(title: sortOption, style: .default, handler: sortSelectedOrAllItems))
		}
		alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		present(alertController, animated: true, completion: nil)
	}
	
	func sortSelectedOrAllItems(sender: UIAlertAction) {
		// WARNING: I haven’t tested this when the table view has more than 1 section.
		// This should only be called if shouldAllowSorting() is true, so it assumes that a valid set of rows is selected.
		
		// Get the rows to sort.
		let selectedIndexPaths = selectedOrAllIndexPathsSortedIn(section: 0, firstRow: 0, lastRow: activeLibraryItems.count - 1)
		
		// Continue in a separate function. This lets SongsTVC override the current function to hack selectedIndexPaths. This is bad practice.
		sortSelectedOrAllItemsPart2(selectedIndexPaths: selectedIndexPaths, sender: sender)
	}
	
	func sortSelectedOrAllItemsPart2(selectedIndexPaths: [IndexPath], sender: UIAlertAction) {
		
		// Get the items to sort, too.
		let selectedIndexPathsAndItems = dataObjectsPairedWith(selectedIndexPaths, tableViewDataSource: activeLibraryItems) as! [(IndexPath, NSManagedObject)]
		
		// Sort the rows and items together.
		let sortOption = sender.title
		let sortedIndexPathsAndItems = sortThese(indexPathsAndItems: selectedIndexPathsAndItems, by: sortOption)
		
		// Remove the selected items from the data source.
		for indexPath in selectedIndexPaths.reversed() {
			activeLibraryItems.remove(at: indexPath.row)
		}
		
		// Put the sorted items into the data source.
		for indexPathAndItem in sortedIndexPathsAndItems.reversed() {
			activeLibraryItems.insert(indexPathAndItem.1, at: selectedIndexPaths.first!.row)
		}
		
		// Update the table view.
		var sortedIndexPaths = [IndexPath]()
		for indexPathAndItem in sortedIndexPathsAndItems {
			sortedIndexPaths.append(indexPathAndItem.0)
		}
		moveRowsUpToEarliestRow(sortedIndexPaths) // You could use tableView.reloadRows, but none of those animations show the individual rows moving to their destinations.
		
		// Update the rest of the UI.
		for indexPath in selectedIndexPaths {
			tableView.deselectRow(at: indexPath, animated: true)
		}
		updateBarButtonItems()
	}
	
	// After editing the sort options, update this class's default sortOptions property (at the top of the file) to include all the options.
	// Sorting should be stable! Multiple items with the same name, year, or whatever property we're sorting by should stay in the same order.
	func sortThese(indexPathsAndItems: [(IndexPath, NSManagedObject)], by sortOption: String?) -> [(IndexPath, NSManagedObject)] { // Make a SortOption enum.
		switch sortOption {
		case "Title":
			// Should we ignore words like "the" and "a" at the starts of titles? Which words should we ignore?
			return indexPathsAndItems.sorted(by: {
				($0.1.value(forKey: "title") as? String ?? "") < ($1.1.value(forKey: "title") as? String ?? "")
			} )
		case "Track Number":
			return indexPathsAndItems.sorted(by: {
				(($0.1.value(forKey: "trackNumber") as! Int) < ($1.1.value(forKey: "trackNumber") as! Int))
			} )
		default:
			print("The user tried to sort by “\(sortOption ?? "")”, which isn’t a supported option. It might be misspelled.")
			return indexPathsAndItems // Otherwise, the app will crash when it tries to call moveRowsUpToEarliestRow on an empty array. Escaping here is easier than changing the logic to use optionals.
		}
	}
	
}
