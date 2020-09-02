//
//  LibraryTVC.swift
//  LavaRock
//
//  Created by h on 2020-04-15.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import CoreData
import MediaPlayer

class LibraryTVC:
	UITableViewController//,
	//NSFetchedResultsControllerDelegate
{
	
	// MARK: - Properties
	
	// "Constants" that subclasses should customize
	var coreDataEntityName = "Collection"
	var containerOfData: NSManagedObject?
	
	// "Constants" that subclasses can optionally customize
	var managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext // Replace this with a child managed object context when in "moving albums" mode.
	var navigationItemButtonsNotEditMode = [UIBarButtonItem]()
	var navigationItemButtonsEditModeOnly = [UIBarButtonItem]()
	var sortOptions = [String]()
	
	// "Constants" that subclasses should not change
	let mediaPlayerManager = (UIApplication.shared.delegate as! AppDelegate).mediaPlayerManager
	let cellReuseIdentifier = "Cell"
	lazy var floatToTopButton = UIBarButtonItem(
		image: UIImage(systemName: "arrow.up.to.line.alt"), // Needs VoiceOver hint
		style: .plain,
		target: self,
		action: #selector(moveSelectedItemsToTop))
	lazy var sortButton = UIBarButtonItem(
		image: UIImage(systemName: "arrow.up.arrow.down"), // Needs VoiceOver hint
		style: .plain,
		target: self,
		action: #selector(showSortOptions))
	lazy var cancelMoveAlbumsButton = UIBarButtonItem(
		barButtonSystemItem: .cancel,
		target: self,
		action: #selector(cancelMoveAlbums))
//	var fetchedResultsController: NSFetchedResultsController<NSManagedObject>?
	
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
	var respondsToWillSaveChangesFromAppleMusicLibraryNotifications = true
	var shouldRespondToNextManagedObjectContextDidSaveNotification = false
//	var isUserCurrentlyMovingRowManually = false
	
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
		
		startObservingNotifications()
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
		if let containerOfData = containerOfData {
			coreDataFetchRequest.predicate = NSPredicate(format: "container == %@", containerOfData)
		}
		
//		updateFetchedResultsController()
		
		activeLibraryItems = managedObjectContext.objectsFetched(for: coreDataFetchRequest)
	}
	
	/*
	func updateFetchedResultsController() {
		NSFetchedResultsController<NSManagedObject>.deleteCache(withName: fetchedResultsController?.cacheName)

		if let containerOfData = containerOfData {
			coreDataFetchRequest.predicate = NSPredicate(format: "container == %@", containerOfData)
		}
		fetchedResultsController = NSFetchedResultsController(
			fetchRequest: coreDataFetchRequest,
			managedObjectContext: managedObjectContext,
			sectionNameKeyPath: nil,
			cacheName: nil
		)
		fetchedResultsController?.delegate = self

		do {
			try fetchedResultsController?.performFetch()
		} catch {
			fatalError("Initialized an NSFetchedResultsController, but couldn't fetch objects.")
		}
	}
	*/
	
	// MARK: Teardown
	
	deinit {
		endObservingNotifications()
	}
	
	// MARK: - Fetched Results Controller Delegate
	
	/*
	func controller(
		_ controller: NSFetchedResultsController<NSFetchRequestResult>,
		didChange anObject: Any,
		at indexPath: IndexPath?,
		for type: NSFetchedResultsChangeType,
		newIndexPath: IndexPath?
	) {
//		guard !isUserCurrentlyMovingRowManually else {
//			fatalError("The NSFetchedResultsController reported that an item should be moved automatically while the user was already moving an item manually.")
//		} // What if the controller reports that an object moved in the data layer, and the user is currently moving an object manually?
		
		print("NSFetchedResultsController has detected a change to the object: \(anObject)")
		print("It thinks the type of change should be: \(type)")
	}
	*/
	
	// MARK: - Events
	
	func refreshNavigationBarButtons() {
		if
			MPMediaLibrary.authorizationStatus() == .authorized,
//			(fetchedResultsController?.fetchedObjects?.count ?? 0) >= 1
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
	
	// MARK: Navigation
	
	override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
		return !isEditing
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if
			segue.identifier == "Drill Down in Library",
			let destination = segue.destination as? LibraryTVC,
			let selectedIndexPath = tableView.indexPathForSelectedRow//,
//			let selectedItem = fetchedResultsController?.object(at: selectedIndexPath)
		{
			let selectedItem = activeLibraryItems[selectedIndexPath.row]
			destination.containerOfData = selectedItem
			destination.managedObjectContext = managedObjectContext
		}
		
		super.prepare(for: segue, sender: sender)
	}
	
}
