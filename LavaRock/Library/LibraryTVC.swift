//
//  LibraryTVC.swift
//  LavaRock
//
//  Created by h on 2020-04-15.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import CoreData
import SwiftUI
import MediaPlayer

class LibraryTVC: UITableViewController {
	
	// MARK: Properties
	
	// "Constants" that subclasses should customize
	var coreDataEntityName = "Collection"
	var containerOfData: NSManagedObject?
	
	// "Constants" that subclasses can optionally customize
	var coreDataManager = CoreDataManager(managedObjectContext: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext) // Inject a child managed object context when in "move albums" mode.
	var navigationItemButtonsNotEditMode = [UIBarButtonItem]()
	var navigationItemButtonsEditModeOnly = [UIBarButtonItem]()
	var sortOptions = [String]()
	
	// "Constants" that subclasses should not change
	let mediaLibraryManager = (UIApplication.shared.delegate as! AppDelegate).mediaLibraryManager
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
	lazy var cancelMoveAlbumsButton = UIBarButtonItem(
		barButtonSystemItem: .cancel,
		target: self,
		action: #selector(cancelMoveAlbums)
	)
	
	// Variables
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
	
	// MARK: Property Observers
	
	func didSetActiveLibraryItems() {
		for index in 0..<self.activeLibraryItems.count {
			activeLibraryItems[index].setValue(index, forKey: "index")
		}
	}
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setUpUI()
		loadSavedLibraryItems()
	}
	
	func setUpUI() {
		navigationItem.leftBarButtonItems = navigationItemButtonsNotEditMode
		navigationItem.rightBarButtonItem = editButtonItem
		navigationItemButtonsEditModeOnly = [floatToTopButton]
		
		refreshNavigationBarButtons()
		
		tableView.tableFooterView = UIView() // Removes the blank cells after the content ends. You can also drag in an empty View below the table view in the storyboard, but that also removes the separator below the last cell.
	}
	
	// MARK: Loading Data
	
	func loadSavedLibraryItems() {
		if containerOfData != nil {
			coreDataFetchRequest.predicate = NSPredicate(format: "container == %@", containerOfData!)
		}
		
		activeLibraryItems = coreDataManager.managedObjects(for: coreDataFetchRequest)
	}
	
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
			if activeLibraryItems.count > 0 {
				tableView.backgroundView = nil
				return activeLibraryItems.count
			} else {
				let noItemsView = tableView.dequeueReusableCell(withIdentifier: "No Items Cell")! // We need a copy of this cell in every scene in the storyboard that might use it.
				tableView.backgroundView = noItemsView
				return 0
			}
		default:
			tableView.backgroundView = nil
			return 1 // "Allow Access" cell
		}
    }
	
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return allowAccessCell(for: indexPath)
		}
		
		// Get the data to put into the cell.
		let cellItem = activeLibraryItems[indexPath.row]
		let cellTitle = cellItem.value(forKey: "title") as? String
		
		// Make, configure, and return the cell.
		let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
		if #available(iOS 14, *) {
			var configuration = cell.defaultContentConfiguration()
			configuration.text = cellTitle
			cell.contentConfiguration = configuration
		} else { // iOS 13 and earlier
			cell.textLabel?.text = cellTitle
		}
        return cell
    }
	
	func allowAccessCell(for indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Allow Access Cell", for: indexPath) // We need a copy of this cell in every scene in the storyboard that might use it.
		if #available(iOS 14.0, *) {
			var configuration = UIListContentConfiguration.cell()
			configuration.text = "Allow Access to Apple Music"
			configuration.textProperties.color = view.window!.tintColor
			cell.contentConfiguration = configuration
		} else { // iOS 13 and earlier
			cell.textLabel?.textColor = view.window?.tintColor
		}
		return cell
	}
	
	// MARK: - Events
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		if isEditing {
			coreDataManager.save()
		}
		
		super.setEditing(editing, animated: animated)
		
		refreshNavigationBarButtons()
		
		// Makes the cells resize themselves (expand if text has wrapped around to new lines; shrink if text has unwrapped into fewer lines).
		// Otherwise, they'll stay the same size until they reload some other time, like after you edit them or they leave memory.
		tableView.performBatchUpdates(nil, completion: nil)
	}
	
	func refreshNavigationBarButtons() {
		if
			MPMediaLibrary.authorizationStatus() == .authorized,
			activeLibraryItems.count >= 1
		{
			editButtonItem.isEnabled = true
		} else {
			editButtonItem.isEnabled = false
		}
		
		if isEditing {
			floatToTopButton.isEnabled = shouldAllowFloatingToTop(indexPathsForSelectedRows: tableView.indexPathsForSelectedRows)
			sortButton.isEnabled = shouldAllowSorting()
			navigationItem.setLeftBarButtonItems(navigationItemButtonsEditModeOnly, animated: true)
		} else {
			navigationItem.setLeftBarButtonItems(navigationItemButtonsNotEditMode, animated: true)
		}
	}
	
	@objc func cancelMoveAlbums() {
		dismiss(animated: true, completion: nil)
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		switch MPMediaLibrary.authorizationStatus() {
		case .authorized:
			break
		case .notDetermined: // The golden opportunity.
			MPMediaLibrary.requestAuthorization() { newStatus in // Fires the alert asking the user for access.
				switch newStatus {
				case .authorized:
					DispatchQueue.main.async {
						MediaPlayerManager.setDefaultLibraryIfAuthorized()
						self.viewDidLoad()
						switch self.tableView(tableView, numberOfRowsInSection: 0) { // tableView.numberOfRows might not be up to date yet. Call the actual UITableViewDelegate method.
						case 0:
							tableView.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
						case 1:
							tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .middle)
						default:
							tableView.performBatchUpdates({
								tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .middle)
								tableView.insertRows(at: self.indexPathsEnumeratedIn(section: 0, firstRow: 1, lastRow: self.tableView(tableView, numberOfRowsInSection: 0) - 1), with: .middle)
							}, completion: nil)
						}
					}
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
	
	override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
		refreshNavigationBarButtons()
	}
	
	override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
		return !isEditing
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if
			segue.identifier == "Drill Down in Library",
			let destination = segue.destination as? LibraryTVC,
			tableView.indexPathForSelectedRow != nil
		{
			let selectedItem = activeLibraryItems[tableView.indexPathForSelectedRow!.row]
			destination.containerOfData = selectedItem
			destination.coreDataManager = coreDataManager
		}
		
		super.prepare(for: segue, sender: sender)
	}
	
//	@IBSegueAction func drillDownInLibrarySwiftUI(_ coder: NSCoder) -> UIViewController? {
//		let selectedItem = activeLibraryItems[tableView.indexPathForSelectedRow!.row]
//		let selectedItemTitle = selectedItem.value(forKey: "title") as! String
//		let destination = UIHostingController(coder: coder, rootView: SongsView())
//		// As of iOS 13.5.1, if you set .navigationBarTitle within SongsView, it doesn't animate in; it just appears after the show segue finishes.
//		destination?.navigationItem.title = selectedItemTitle
//		return destination
//	}
	
	// MARK: - Rearranging
	
	override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
		let itemBeingMoved = activeLibraryItems[fromIndexPath.row]
		activeLibraryItems.remove(at: fromIndexPath.row)
		activeLibraryItems.insert(itemBeingMoved, at: to.row)
		refreshNavigationBarButtons() // If you made selected items non-consecutive, that should disable the Sort button. If you made selected items consecutive, that should enable the Sort button.
	}
	
	// MARK: Moving Rows to Top
	
	@objc func moveSelectedItemsToTop() {
		moveItemsUp(from: tableView.indexPathsForSelectedRows, to: IndexPath(row: 0, section: 0))
	}
	
	// NOTE: Every IndexPath in selectedIndexPaths must be in the same section as targetIndexPath, and at or down below targetIndexPath.
	func moveItemsUp(from selectedIndexPaths: [IndexPath]?, to firstIndexPath: IndexPath) {
		
		guard
			let indexPaths = selectedIndexPaths,
			shouldAllowFloatingToTop(indexPathsForSelectedRows: selectedIndexPaths)
		else {
			return
		}
		for indexPath in indexPaths {
			if indexPath.section != firstIndexPath.section || indexPath.row < firstIndexPath.row {
				return
			}
		}
		
		let pairsToMove = dataObjectsPairedWith(indexPaths.sorted(), tableViewDataSource: activeLibraryItems) as! [(IndexPath, NSManagedObject)]
		let targetSection = firstIndexPath.section
		var targetRow = firstIndexPath.row
		for (indexPath, libraryItem) in pairsToMove {
			tableView.moveRow(at: indexPath, to: IndexPath(row: targetRow, section: targetSection))
			activeLibraryItems.remove(at: indexPath.row)
			activeLibraryItems.insert(libraryItem, at: targetRow)
			tableView.deselectRow(at: IndexPath(row: targetRow, section: targetSection), animated: true) // Wait until after all the rows have moved to do this?
			targetRow += 1
		}
		refreshNavigationBarButtons()
	}
	
	// MARK: Sorting
	
	// Unfortunately, we can't save UIAlertActions as constant properties of LibraryTVC. They're view controllers.
	@objc func showSortOptions() {
		let alertController = UIAlertController(title: "Sort By", message: nil, preferredStyle: .actionSheet)
		for sortOption in sortOptions {
			alertController.addAction(UIAlertAction(title: sortOption, style: .default, handler: sortSelectedOrAllItems))
		}
		alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		present(alertController, animated: true, completion: nil)
	}
	
	func sortSelectedOrAllItems(sender: UIAlertAction) {
		// Get the rows to sort.
		let selectedIndexPaths = selectedOrAllIndexPathsSortedIn(section: 0, firstRow: 0, lastRow: activeLibraryItems.count - 1)
		
		// Continue in a separate function. This lets SongsTVC override the current function to hack selectedIndexPaths. This is bad practice.
		sortSelectedOrAllItemsPart2(selectedIndexPaths: selectedIndexPaths, sender: sender)
	}
	
	func sortSelectedOrAllItemsPart2(selectedIndexPaths: [IndexPath], sender: UIAlertAction) {
		
		guard shouldAllowSorting() else { return }
		
		// Get the items to sort, too.
		let selectedIndexPathsAndItems = dataObjectsPairedWith(selectedIndexPaths, tableViewDataSource: activeLibraryItems) as! [(IndexPath, NSManagedObject)]
		
		// Sort the rows and items together.
		let sortOption = sender.title
		let sortedIndexPathsAndItems = sorted(indexPathsAndItems: selectedIndexPathsAndItems, by: sortOption)
		
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
		refreshNavigationBarButtons()
	}
	
	// After editing the sort options, update this class's default sortOptions property (at the top of the file) to include all the options.
	// Sorting should be stable! Multiple items with the same name, year, or whatever property we're sorting by should stay in the same order.
	func sorted(indexPathsAndItems: [(IndexPath, NSManagedObject)], by sortOption: String?) -> [(IndexPath, NSManagedObject)] { // Make a SortOption enum.
		switch sortOption {
		
		/*
		case "Title":
			// Ignore articles ("the", "a", and "an")?
			return indexPathsAndItems.sorted(by: {
				
				// If we're sorting collections:
				($0.1.value(forKey: "title") as? String ?? "") < ($1.1.value(forKey: "title") as? String ?? "")
				
				// If we're sorting albums or songs, use the methods in `extension Album` or `extension Song` to fetch their titles (or placeholders).
				
				
			} )
			*/
		
		case "Track Number":
			// Actually, return the items grouped by disc number, and sorted by track number within each disc.
			let sortedByTrackNumber = indexPathsAndItems.sorted(by: {
				(($0.1 as? Song)?.trackNumber ?? 0) < (($1.1 as? Song)?.trackNumber ?? 0) // This is putting songs with unknown track numbers at the top, which doesn't look right.
			} )
			return sortedByTrackNumber.sorted(by: {
				(($0.1 as? Song)?.discNumber ?? 0) < (($1.1 as? Song)?.discNumber ?? 0) // This is putting songs with unknown disc numbers at the top, which doesn't look right.
			} )
			
		default:
			print("The user tried to sort by “\(sortOption ?? "")”, which isn’t a supported option. It might be misspelled.")
			return indexPathsAndItems // Otherwise, the app will crash when it tries to call moveRowsUpToEarliestRow on an empty array. Escaping here is easier than changing the logic to use optionals.
		}
	}
	
}
