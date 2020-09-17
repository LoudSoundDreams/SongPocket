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
	UITableViewController,
	PlaybackToolbarManager//,
	//NSFetchedResultsControllerDelegate
{
	
	// MARK: - Properties
	
	// MARK: "Constants"
	
	// "Constants" that subclasses should customize
	var coreDataEntityName = "Collection"
	var containerOfData: NSManagedObject?
	
	// "Constants" that subclasses can optionally customize
	var managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext // Replace this with a child managed object context when in "moving albums" mode.
	var navigationItemButtonsNotEditingMode = [UIBarButtonItem]()
	var navigationItemButtonsEditingModeOnly = [UIBarButtonItem]()
	var toolbarButtonsEditingModeOnly = [UIBarButtonItem]()
	var sortOptions = [String]()
	
	// "Constants" that subclasses should not change
	let cellReuseIdentifier = "Cell"
	lazy var floatToTopButton = UIBarButtonItem(
		image: UIImage(systemName: "arrow.up.to.line.alt"), // Needs VoiceOver hint
		style: .plain,
		target: self,
		action: #selector(moveSelectedItemsToTop))
	lazy var sortButton = UIBarButtonItem(
		title: "Sort",
		style: .plain,
		target: self,
		action: #selector(showSortOptions))
	lazy var cancelMoveAlbumsButton = UIBarButtonItem(
		barButtonSystemItem: .cancel,
		target: self,
		action: #selector(cancelMoveAlbums))
//	var fetchedResultsController: NSFetchedResultsController<NSManagedObject>?
	
	// "Constants" that subclasses should not change, for PlaybackToolbarManager
	var playerController: MPMusicPlayerController?
	lazy var goToPreviousSongButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			image: UIImage(systemName: "backward.end.fill"),
			style: .plain,
			target: self,
			action: #selector(goToPreviousSong))
		button.width = CGFloat(10.0)
		return button
	}()
	lazy var restartCurrentSongButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			image: UIImage(systemName: "arrow.counterclockwise.circle.fill"),
			style: .plain,
			target: self,
			action: #selector(restartCurrentSong))
		button.width = CGFloat(10.0)
		return button
	}()
	lazy var playButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			image: UIImage(systemName: "play.fill"),
			style: .plain,
			target: self,
			action: #selector(play))
		button.width = CGFloat(10.0)
		return button
	}()
	lazy var pauseButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			image: UIImage(systemName: "pause.fill"),
			style: .plain,
			target: self,
			action: #selector(pause))
		button.width = CGFloat(10.0) // As of iOS 14.0 beta 8, even with this line of code, the "pause.fill" button is still narrower than the "play.fill" button.
		return button
	}()
	lazy var goToNextSongButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			image: UIImage(systemName: "forward.end.fill"),
			style: .plain,
			target: self,
			action: #selector(goToNextSong))
		button.width = CGFloat(10.0)
		return button
	}()
	let flexibleSpaceBarButtonItem = UIBarButtonItem(
		barButtonSystemItem: .flexibleSpace,
		target: nil,
		action: nil)
	
	// MARK: Variables
	
	var numberOfRowsAboveIndexedLibraryItems = 0 // This is implied to be true in each section. numberOfRowsInEachSectionAboveIndexedLibraryItems would be a more explicit name.
	var indexedLibraryItems = [NSManagedObject]() { // The truth for the order of items is their order in this array, because the table view follows this array; not the "index" attribute of each NSManagedObject.
		// WARNING: indexedLibraryItems[indexPath.row] will not necessarily get the right library item. Whenever you use both indexedLibraryItems and IndexPaths, always subtract from indexPath.row numberOfRowsAboveIndexedLibraryItems, even if it's 0.
		// This is a hack to allow other rows in the table view above the rows for indexedLibraryItems. This lets us use table view rows for album artwork and album info in SongsTVC. We can also use this for All Albums and New Collection buttons in CollectionsTVC, and All Songs and Move Here buttons in AlbumsTVC.
		didSet {
			for index in 0 ..< indexedLibraryItems.count {
				indexedLibraryItems[index].setValue(Int64(index), forKey: "index")
			}
		}
	}
	lazy var coreDataFetchRequest: NSFetchRequest<NSManagedObject> = {
		let request = NSFetchRequest<NSManagedObject>(entityName: coreDataEntityName)
		request.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		return request
	}()
	var refreshesAfterDidSaveChangesFromAppleMusic = true
	var shouldRefreshOnNextViewDidAppear = false
	var areSortOptionsPresented = false
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setUpPlayerControllerIfAuthorized() // We need to do this before beginObservingAndGeneratingNotifications(), because we need to tell the player controller to begin generating notifications.
		beginObservingAndGeneratingNotifications()
		reloadIndexedLibraryItems()
		setUpUI()
	}
	
	private func setUpPlayerControllerIfAuthorized() {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		playerController = MPMusicPlayerController.systemMusicPlayer
	}
	
	// MARK: Loading Data
	
	final func reloadIndexedLibraryItems() {
		if let containerOfData = containerOfData {
			coreDataFetchRequest.predicate = NSPredicate(format: "container == %@", containerOfData)
		}
		
//		updateFetchedResultsController()
		
		indexedLibraryItems = managedObjectContext.objectsFetched(for: coreDataFetchRequest)
	}
	
	/*
	private func updateFetchedResultsController() {
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
	
	// MARK: Setting Up UI
	
	func setUpUI() {
		tableView.tableFooterView = UIView() // Removes the blank cells after the content ends. You can also drag in an empty View below the table view in the storyboard, but that also removes the separator below the last cell.
		
		navigationItemButtonsEditingModeOnly = [floatToTopButton]
		navigationItem.rightBarButtonItem = editButtonItem
		setRefreshedBarButtons(animated: true)
	}
	
	// MARK: Setup Events
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if shouldRefreshOnNextViewDidAppear {
			shouldRefreshOnNextViewDidAppear = false
			refreshDataAndViews()
		}
	}
	
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
	// What if the controller reports that an object moved in the data layer, and the user is currently moving an object manually?
		
		print("NSFetchedResultsController has detected a change to the object: \(anObject)")
		print("It thinks the type of change should be: \(type)")
	}
	*/
	
	// MARK: - Events
	
	final func setRefreshedBarButtons(animated: Bool) {
		refreshBarButtons(animated: animated) // Includes setRefreshedPlaybackToolbar(animated:).
		
		if isEditing {
			navigationItem.setLeftBarButtonItems(navigationItemButtonsEditingModeOnly, animated: animated)
			setToolbarItems(toolbarButtonsEditingModeOnly, animated: animated)
		} else {
			navigationItem.setLeftBarButtonItems(navigationItemButtonsNotEditingMode, animated: animated)
		}
	}
	
	func refreshBarButtons(animated: Bool = false) {
		// Remember: There can momentarily be 0 items in indexedLibraryItems if we're refreshing the UI to reflect changes in the Apple Music library.
		refreshEditButton()
		if isEditing {
			refreshFloatToTopButton()
			refreshSortButton()
		} else {
			setRefreshedPlaybackToolbar(animated: animated)
		}
	}
	
	private func refreshEditButton() {
		editButtonItem.isEnabled =
			MPMediaLibrary.authorizationStatus() == .authorized &&
//			(fetchedResultsController?.fetchedObjects?.count ?? 0) > 0
			indexedLibraryItems.count > 0
	}
	
	private func refreshFloatToTopButton() {
		floatToTopButton.isEnabled =
			indexedLibraryItems.count > 0 &&
			shouldAllowFloatingToTop(forIndexPaths: tableView.indexPathsForSelectedRows)
	}
	
	private func refreshSortButton() {
		sortButton.isEnabled =
			indexedLibraryItems.count > 0 &&
			shouldAllowSorting()
		if tableView.indexPathsForSelectedRows == nil {
			sortButton.title = "Sort All"
		} else {
			sortButton.title = "Sort"
		}
	}
	
	@objc private func cancelMoveAlbums() {
		dismiss(animated: true, completion: nil)
	}
	
	// MARK: - Navigation
	
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
			destination.managedObjectContext = managedObjectContext
			let selectedItem = indexedLibraryItems[selectedIndexPath.row - numberOfRowsAboveIndexedLibraryItems]
			destination.containerOfData = selectedItem
		}
		
		super.prepare(for: segue, sender: sender)
	}
	
}
