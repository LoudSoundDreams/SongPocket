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
	let tintColor = UIColor(named: "accentColors")
	let cellReuseIdentifier = "Cell"
	lazy var floatToTopButton = UIBarButtonItem(
		image: UIImage(systemName: "arrow.up.to.line"), // Needs VoiceOver hint
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
	var collectionsNC = CollectionsNC()
	
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
	
	// MARK: Property observers
	
	func didSetActiveLibraryItems() {
		collectionsNC.managedObjectContext.performAndWait {
			for index in 0..<self.activeLibraryItems.count {
				self.activeLibraryItems[index].setValue(index, forKey: "index")
			}
		}
	}
	
	// MARK: Setup
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		collectionsNC = navigationController as! CollectionsNC
		
		setUpUI()
		loadViaCurrentManagedObjectContext()
	}
	
	// MARK: Setting up UI
	
	func setUpUI() {
		
		// Always
		if containerOfData != nil {
			title = containerOfData?.value(forKey: "title") as? String
		}
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
			barButtonItemsEditMode = [floatToTopButton]
			navigationItem.rightBarButtonItem = editButtonItem
			
			navigationController?.isToolbarHidden = true
		}
		
	}
	
	// MARK: Loading data
	
	func loadViaCurrentManagedObjectContext() {
		if containerOfData != nil {
			coreDataFetchRequest.predicate = NSPredicate(format: "container == %@", containerOfData!)
		}
		
		collectionsNC.managedObjectContext.performAndWait {
			do {
				self.activeLibraryItems = try self.collectionsNC.managedObjectContext.fetch(self.coreDataFetchRequest)
			} catch {
				print("Couldn’t load from Core Data using the fetch request: \(self.coreDataFetchRequest)")
				fatalError("\(error)")
			}
		}
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return activeLibraryItems.count
    }
	
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
		
		// Get the data to put into the cell.
		let libraryItem = activeLibraryItems[indexPath.row]
		
		// Put the data into the cell.
		cell.textLabel?.text = libraryItem.value(forKey: "title") as? String
		
        return cell
    }
	
	// MARK: Events
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		if isEditing {
			collectionsNC.saveCurrentManagedObjectContext()
		}
		
		super.setEditing(editing, animated: animated)
		
		updateBarButtonItems()
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
//		let destination = UIHostingController(coder: coder, rootView: SongsList())
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
	
	// MARK: Moving rows to top
	
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
		var selectedIndexPaths = [IndexPath]()
		if let selected = tableView.indexPathsForSelectedRows { // If any rows are selected.
			// WARNING: Only works if the selected rows are consecutive.
			selectedIndexPaths = selected.sorted()
		} else { // If no rows are selected, sort all the rows.
			selectedIndexPaths = indexPathsEnumeratedIn(section: 0, firstRow: 0, lastRow: activeLibraryItems.count - 1)
		}
		
		// Get the items to sort, too.
		let selectedIndexPathsAndItems = dataObjectsPairedWith(selectedIndexPaths, tableViewDataSource: activeLibraryItems) as! [(IndexPath, NSManagedObject)]
		
		// Sort the rows and items together.
		let sortOption = sender.title
		let sortedIndexPathsAndItems = sortThese(indexPathsAndItems: selectedIndexPathsAndItems, bySortOption: sortOption)
		
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
	func sortThese(indexPathsAndItems: [(IndexPath, NSManagedObject)], bySortOption: String?) -> [(IndexPath, NSManagedObject)] { // Make a SortOption enum.
		switch bySortOption {
		case "Title":
			// Should we ignore words like "the" and "a" at the starts of titles? Which words should we ignore?
			return indexPathsAndItems.sorted(by: {
				($0.1.value(forKey: "title") as? String ?? "") < ($1.1.value(forKey: "title") as? String ?? "")
			} )
		// TO DO: Add cases for all the sort options here.
		// "Track Number", "Oldest First", "Newest First", "Duration", "Date Modified"
		
		default:
			print("The user tried to sort by “\(bySortOption ?? "")”, which isn’t a supported option. It might be misspelled or not available in the sorting code.")
			return indexPathsAndItems // Otherwise, the app will crash when it tries to call moveRowsUpToEarliestRow on an empty sortItems array. Escaping here is easier than changing the logic to use optionals.
		}
	}
	
}
