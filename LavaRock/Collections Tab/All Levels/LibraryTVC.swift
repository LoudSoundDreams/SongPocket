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
	
	// MARK: - Types
	
	enum SortOption {
		case title
		
		// For Albums only
		case newestFirst
		case oldestFirst
		
		// For Songs only
		case trackNumber
	}
	
	// MARK: - Properties
	
	// MARK: "Constants"
	
	// "Constants" that subclasses should customize
	var coreDataEntityName = "Collection"
	var containerOfLibraryItems: NSManagedObject?
	
	// "Constants" that subclasses can optionally customize
	var managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext // Replace this with a child managed object context when in "moving Albums" mode.
	var numberOfRowsAboveIndexedLibraryItems = 0 // This applies to every section. numberOfRowsInEachSectionAboveIndexedLibraryItems would be a more explicit name.
	var navigationItemLeftButtonsNotEditingMode = [UIBarButtonItem]()
	private var navigationItemLeftButtonsEditingMode = [UIBarButtonItem]()
	private var navigationItemRightButtons = [UIBarButtonItem]()
	var toolbarButtonsEditingModeOnly = [UIBarButtonItem]()
	var sortOptions = [SortOption]()
	
	// "Constants" that subclasses should not change
	var sharedPlayerController: MPMusicPlayerController? {
		PlayerControllerManager.playerController
	}
	let cellReuseIdentifier = "Cell"
	lazy var noItemsPlaceholderView = {
		return tableView?.dequeueReusableCell(withIdentifier: "No Items Placeholder") // Every subclass needs a placeholder cell in the storyboard with this reuse identifier; otherwise, dequeueReusableCell returns nil.
	}()
	lazy var sortButton = UIBarButtonItem(
		title: LocalizedString.sort,
		style: .plain, target: self, action: #selector(showSortOptions))
	lazy var floatToTopButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			image: UIImage(systemName: "arrow.up.to.line.alt"),
			style: .plain, target: self, action: #selector(moveSelectedItemsToTop))
		button.accessibilityLabel = LocalizedString.moveToTop
		return button
	}()
	lazy var sinkToBottomButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			image: UIImage(systemName: "arrow.down.to.line.alt"),
			style: .plain, target: self, action: #selector(sinkSelectedItemsToBottom))
		button.accessibilityLabel = LocalizedString.moveToBottom
		return button
	}()
	lazy var cancelMoveAlbumsButton = UIBarButtonItem(
		barButtonSystemItem: .cancel,
		target: self, action: #selector(cancelMoveAlbums))
	@objc private func cancelMoveAlbums() {
		dismiss(animated: true, completion: nil)
	}
	let flexibleSpaceBarButtonItem = UIBarButtonItem(
		barButtonSystemItem: .flexibleSpace,
		target: nil, action: nil)
	
	// "Constants" that subclasses should not change, for PlaybackToolbarManager
	var playbackToolbarButtons = [UIBarButtonItem]()
	lazy var goToPreviousSongButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			image: UIImage(systemName: "backward.end.fill"),
			style: .plain, target: self, action: #selector(goToPreviousSong))
		button.width = 10.0
		button.accessibilityLabel = LocalizedString.previousTrack
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	lazy var restartCurrentSongButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			image: UIImage(systemName: "arrow.counterclockwise.circle.fill"),
			style: .plain, target: self, action: #selector(restartCurrentSong))
		button.width = 10.0
		button.accessibilityLabel = LocalizedString.restart
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	let playButtonImage = UIImage(systemName: "play.fill")
	let playButtonAction = #selector(play)
	let playButtonAccessibilityLabel = LocalizedString.play
	let playButtonAdditionalAccessibilityTraits: UIAccessibilityTraits = .startsMediaSession
	let pauseButtonImage = UIImage(systemName: "pause.fill")
	let pauseButtonAction = #selector(pause)
	let pauseButtonAccessibilityLabel = LocalizedString.pause
	lazy var playPauseButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			image: playButtonImage,
			style: .plain, target: self, action: playButtonAction)
		button.width = 10.0 // As of iOS 14.2 beta 4, even when you set the width of each button manually, the "pause.fill" button is still narrower than the "play.fill" button.
		button.accessibilityLabel = playButtonAccessibilityLabel
		button.accessibilityTraits.formUnion(playButtonAdditionalAccessibilityTraits)
		return button
	}()
	lazy var goToNextSongButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			image: UIImage(systemName: "forward.end.fill"),
			style: .plain, target: self, action: #selector(goToNextSong))
		button.width = 10.0
		button.accessibilityLabel = LocalizedString.nextTrack
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	
	// MARK: Variables
	
	var indexedLibraryItems = [NSManagedObject]() { // The truth for the order of items is their order in this array, because the table view follows this array; not the "index" attribute of each NSManagedObject.
		// WARNING: indexedLibraryItems[indexPath.row] might return the wrong library item. Whenever you use both indexedLibraryItems and IndexPaths, you must always subtract numberOfRowsAboveIndexedLibraryItems from indexPath.row.
		// This is a hack to allow other rows in the table view above the rows for indexedLibraryItems. This lets us use table view rows for album artwork and album info in SongsTVC. We can also use this for All Albums and New Collection buttons in CollectionsTVC, and All Songs and Move Here buttons in AlbumsTVC.
		didSet {
			for index in 0 ..< indexedLibraryItems.count {
				indexedLibraryItems[index].setValue(Int64(index), forKey: "index")
			}
		}
	}
	lazy var coreDataFetchRequest: NSFetchRequest<NSManagedObject> = { // Make this a computed property?
		let request = NSFetchRequest<NSManagedObject>(entityName: coreDataEntityName)
		request.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
		return request
	}()
	var isEitherLoadingOrUpdating = false
	var shouldRefreshOnNextViewDidAppear = false
	var areSortOptionsPresented = false
//	var isAnimatingDuringRefreshTableView = 0
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setUp()
	}
	
	final func setUp() {
		beginObservingNotifications()
		reloadIndexedLibraryItems()
		setUpUI()
	}
	
	final func reloadIndexedLibraryItems() {
		if let containerOfLibraryItems = containerOfLibraryItems {
			coreDataFetchRequest.predicate = NSPredicate(format: "container == %@", containerOfLibraryItems)
		}
		
		indexedLibraryItems = managedObjectContext.objectsFetched(for: coreDataFetchRequest)
	}
	
	// LibraryTVC itself doesn't call this during viewDidLoad(), but its subclasses may want to.
	// Call this method late into launch, after we've already set up most of the UI; this method sets up the MediaPlayer-related functionality so that we can set up the rest of the UI (although this method itself doesn't set up the rest of the UI).
	// Before calling this method, set isEitherLoadingOrUpdating = true, and put the UI into the "Loading…" or "Updating…" state.
	final func integrateWithAndImportChangesFromMusicLibraryIfAuthorized() {
		MusicLibraryManager.shared.setUpLibraryAndImportChangesIfAuthorized() // During a typical launch, we need to observe the notification after the import completes, so only do this after LibraryTVC's beginObservingNotifications(). After we observe that notification, we refresh our data and views, including the playback toolbar.
		PlayerControllerManager.setUpPlayerControllerIfAuthorized() // This actually doesn't trigger refreshing the playback toolbar; refreshing after importing changes (above) does.
	}
	
	// MARK: Setting Up UI
	
	func setUpUI() {
		tableView.tableFooterView = UIView() // Removes the blank cells after the content ends. You can also drag in an empty View below the table view in the storyboard, but that also removes the separator below the last cell.
		
		navigationItemLeftButtonsEditingMode = [flexibleSpaceBarButtonItem]
		navigationItemRightButtons = [editButtonItem]
		playbackToolbarButtons = [
			goToPreviousSongButton,
			flexibleSpaceBarButtonItem,
			restartCurrentSongButton,
			flexibleSpaceBarButtonItem,
			playPauseButton,
			flexibleSpaceBarButtonItem,
			goToNextSongButton
		]
		refreshAndSetBarButtons(animated: true) // After we receive authorization to access the Music library, we call setUpUI() again, and when that happens, the change should be animated.
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
	
	final func refreshAndSetBarButtons(animated: Bool) {
		refreshBarButtons()
		
		setNavigationItemButtons(animated: animated)
		setToolbarButtons(animated: animated)
	}
	
	private func setNavigationItemButtons(animated: Bool) {
//		if isEitherLoadingOrUpdating {
//			let activityIndicatorView = UIActivityIndicatorView()
//			activityIndicatorView.startAnimating()
//			let spinnerBarButtonItem = UIBarButtonItem(customView: activityIndicatorView)
//			navigationItem.setRightBarButtonItems([spinnerBarButtonItem], animated: animated)
//			return
//		}
		
		if isEditing {
			navigationItem.setLeftBarButtonItems(navigationItemLeftButtonsEditingMode, animated: animated)
		} else {
			navigationItem.setLeftBarButtonItems(navigationItemLeftButtonsNotEditingMode, animated: animated)
		}
		navigationItem.setRightBarButtonItems(navigationItemRightButtons, animated: animated)
	}
	
	func setToolbarButtons(animated: Bool) {
		if isEditing {
			setToolbarItems(toolbarButtonsEditingModeOnly, animated: animated)
		} else {
			setToolbarItems(playbackToolbarButtons, animated: animated)
		}
	}
	
	func refreshBarButtons() {
		// There can momentarily be 0 items in indexedLibraryItems if we're refreshing to reflect changes in the Music library.
		refreshEditButton()
		if isEditing {
			refreshSortButton()
			refreshFloatToTopButton()
			refreshSinkToBottomButton()
		} else {
			refreshPlaybackToolbarButtons()
		}
	}
	
	private func refreshEditButton() {
		editButtonItem.isEnabled =
			MPMediaLibrary.authorizationStatus() == .authorized &&
			!indexedLibraryItems.isEmpty
	}
	
	private func refreshSortButton() {
		sortButton.isEnabled =
			!indexedLibraryItems.isEmpty &&
			tableView.shouldAllowSorting()
	}
	
	private func refreshFloatToTopButton() {
		floatToTopButton.isEnabled =
			!indexedLibraryItems.isEmpty &&
			tableView.shouldAllowMovingSelectedRowsToTopOfSection()
	}
	
	private func refreshSinkToBottomButton() {
		sinkToBottomButton.isEnabled =
			!indexedLibraryItems.isEmpty &&
			tableView.shouldAllowMovingSelectedRowsToBottomOfSection()
	}
	
	// MARK: - Navigation
	
	final override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
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
			destination.containerOfLibraryItems = selectedItem
		}
		
		super.prepare(for: segue, sender: sender)
	}
	
}
