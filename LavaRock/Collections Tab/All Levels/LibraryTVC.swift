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
	PlaybackToolbarManager
{
	
	// MARK: - Properties
	
	// MARK: "Constants"
	
	// "Constants" that subclasses should customize
	var coreDataEntityName = "Collection"
	var containerOfData: NSManagedObject?
	
	// "Constants" that subclasses can optionally customize
	var managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext // Replace this with a child managed object context when in "moving albums" mode.
	var navigationItemButtonsNotEditingMode = [UIBarButtonItem]()
	private var navigationItemButtonsEditingModeOnly = [UIBarButtonItem]()
	var toolbarButtonsEditingModeOnly = [UIBarButtonItem]()
	var sortOptions = [String]()
	
	// "Constants" that subclasses should not change
	let cellReuseIdentifier = "Cell"
	lazy var selectAllOrNoneButton = UIBarButtonItem(
		title: "Select All",
		style: .plain,
		target: self,
		action: #selector(selectAllOrNone))
	lazy var sortButton = UIBarButtonItem(
		title: "Sort",
		style: .plain,
		target: self,
		action: #selector(showSortOptions))
	lazy var floatToTopButton = UIBarButtonItem(
		image: UIImage(systemName: "arrow.up.to.line.alt"), // Needs VoiceOver hint
		style: .plain,
		target: self,
		action: #selector(moveSelectedItemsToTop))
	lazy var cancelMoveAlbumsButton = UIBarButtonItem(
		barButtonSystemItem: .cancel,
		target: self,
		action: #selector(cancelMoveAlbums))
	
	// "Constants" that subclasses should not change, for PlaybackToolbarManager
	var playerController: MPMusicPlayerController?
	lazy var goToPreviousSongButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			image: UIImage(systemName: "backward.end"),
			style: .plain,
			target: self,
			action: #selector(goToPreviousSong))
		button.width = 10.0
		return button
	}()
	lazy var restartCurrentSongButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			image: UIImage(systemName: "arrow.counterclockwise"),
			style: .plain,
			target: self,
			action: #selector(restartCurrentSong))
		button.width = 10.0
		return button
	}()
	lazy var playButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			image: UIImage(systemName: "play"),
			style: .plain,
			target: self,
			action: #selector(play))
		button.width = 10.0
		return button
	}()
	lazy var pauseButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			image: UIImage(systemName: "pause"),
			style: .plain,
			target: self,
			action: #selector(pause))
		button.width = 10.0 // As of iOS 14.0, even when you set the width of each button manually, the "pause.fill" button is still narrower than the "play.fill" button.
		return button
	}()
	lazy var goToNextSongButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			image: UIImage(systemName: "forward.end"),
			style: .plain,
			target: self,
			action: #selector(goToNextSong))
		button.width = 10.0
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
		
		indexedLibraryItems = managedObjectContext.objectsFetched(for: coreDataFetchRequest)
	}
	
	// MARK: Setting Up UI
	
	func setUpUI() {
		tableView.tableFooterView = UIView() // Removes the blank cells after the content ends. You can also drag in an empty View below the table view in the storyboard, but that also removes the separator below the last cell.
		
		navigationItemButtonsEditingModeOnly = [selectAllOrNoneButton]
//		navigationItemButtonsEditingModeOnly = [flexibleSpaceBarButtonItem]
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
	
	// MARK: - Events
	
	func setRefreshedBarButtons(animated: Bool) {
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
			refreshSelectAllOrNoneButton()
			refreshSortButton()
			refreshFloatToTopButton()
		} else {
			setRefreshedPlaybackToolbar(animated: animated)
		}
	}
	
	private func refreshEditButton() {
		editButtonItem.isEnabled =
			MPMediaLibrary.authorizationStatus() == .authorized &&
			indexedLibraryItems.count > 0
	}
	
	private func refreshSelectAllOrNoneButton() {
		if
			let selectedIndexPaths = tableView.indexPathsForSelectedRows,
			selectedIndexPaths.count == indexedLibraryItems.count
		{
			selectAllOrNoneButton.title = "Select None"
		} else {
			selectAllOrNoneButton.title = "Select All"
		}
	}
	
	private func refreshSortButton() {
		sortButton.isEnabled =
			indexedLibraryItems.count > 0 &&
			tableView.indexPathsForSelectedRows != nil &&
			shouldAllowSorting()
//		if tableView.indexPathsForSelectedRows == nil {
//			sortButton.title = "Sort All"
//		} else {
//			sortButton.title = "Sort"
//		}
	}
	
	private func refreshFloatToTopButton() {
		floatToTopButton.isEnabled =
			indexedLibraryItems.count > 0 &&
			shouldAllowFloatingToTop(forIndexPaths: tableView.indexPathsForSelectedRows)
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
			let selectedIndexPath = tableView.indexPathForSelectedRow
		{
			destination.managedObjectContext = managedObjectContext
			let selectedItem = indexedLibraryItems[selectedIndexPath.row - numberOfRowsAboveIndexedLibraryItems]
			destination.containerOfData = selectedItem
		}
		
		super.prepare(for: segue, sender: sender)
	}
	
}
