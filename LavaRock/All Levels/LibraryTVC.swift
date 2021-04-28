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
		// For Collections only
		case title
		
		// For Albums only
		case newestFirst
		case oldestFirst
		
		// For Songs only
		case trackNumber
		
		// For all types
		case reverse
		
		// You can't have each LocalizedString be a raw value for an enum case, because raw values for enum cases must be literals.
		func localizedName() -> String {
			switch self {
			case .title:
				return LocalizedString.title
			case .newestFirst:
				return LocalizedString.newestFirst
			case .oldestFirst:
				return LocalizedString.oldestFirst
			case .trackNumber:
				return LocalizedString.trackNumber
			case .reverse:
				return LocalizedString.reverse
			}
		}
	}
	
	// MARK: - Properties
	
	// MARK: "Constants"
	
	// "Constants" that subclasses should customize
	var entityName = "Collection"
	var bottomButtonsInEditingMode = [UIBarButtonItem]()
	var sortOptions = [SortOption]() {
		didSet {
			if #available(iOS 14, *) {
				let sortActions = sortOptions.map {
					UIAction(
						title: $0.localizedName(),
						handler: sortActionHandler(_:))
				}
				sortButton.menu = UIMenu(children: sortActions.reversed()) // Reversed because a UIMenu lists its children from the bottom upward when a toolbar button presents it.
			}
		}
	}
	
	// "Constants" that subclasses can optionally customize
	var managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext // Replace this with a child managed object context when in "moving Albums" mode.
	var numberOfRowsInSectionAboveLibraryItems = 0
	var topLeftButtonsInViewingMode = [UIBarButtonItem]()
	private lazy var topLeftButtonsInEditingMode = [flexibleSpaceBarButtonItem]
	lazy var topRightButtons = [editButtonItem]
	lazy var bottomButtonsInViewingMode = playbackToolbarButtons
	
	// "Constants" that subclasses should not change
	var sharedPlayerController: MPMusicPlayerController? {
		PlayerControllerManager.playerController
	}
	let cellReuseIdentifier = "Cell"
	lazy var noItemsPlaceholderView = {
		return tableView?.dequeueReusableCell(withIdentifier: "No Items Placeholder") // Every subclass needs a placeholder cell in the storyboard with this reuse identifier.
	}()
	lazy var sortButton: UIBarButtonItem = {
		if #available(iOS 14, *) {
			return UIBarButtonItem(
				title: LocalizedString.sort) // The property observer on sortOptions adds a UIMenu to this button.
		} else { // iOS 13
			return UIBarButtonItem(
				title: LocalizedString.sort,
				style: .plain, target: self, action: #selector(showSortOptionsActionSheet))
		}
	}()
	lazy var floatToTopButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			image: UIImage(systemName: "arrow.up.to.line.alt"),
			style: .plain, target: self, action: #selector(floatSelectedItemsToTopOfSection))
		button.accessibilityLabel = LocalizedString.moveToTop
		return button
	}()
	lazy var sinkToBottomButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			image: UIImage(systemName: "arrow.down.to.line.alt"),
			style: .plain, target: self, action: #selector(sinkSelectedItemsToBottomOfSection))
		button.accessibilityLabel = LocalizedString.moveToBottom
		return button
	}()
	lazy var cancelMoveAlbumsButton = UIBarButtonItem(
		barButtonSystemItem: .cancel,
		target: self, action: #selector(cancelMoveAlbums))
	@objc private func cancelMoveAlbums() {
		dismiss(animated: true)
	}
	let flexibleSpaceBarButtonItem = UIBarButtonItem(
		barButtonSystemItem: .flexibleSpace,
		target: nil, action: nil)
	
	// "Constants" that subclasses should not change, for PlaybackToolbarManager
	lazy var playbackToolbarButtons = [
		goToPreviousSongButton,
		flexibleSpaceBarButtonItem,
		restartCurrentSongButton,
		flexibleSpaceBarButtonItem,
		playPauseButton,
		flexibleSpaceBarButtonItem,
		goToNextSongButton
	]
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
	
	lazy var sectionOfLibraryItems = SectionOfLibraryItems(
		managedObjectContext: managedObjectContext,
		container: nil,
		entityName: entityName)
	var isImportingChanges = false
//	var isUpdating: Bool {
//		return
//			isImportingChanges &&
//			!sectionOfLibraryItems.items.isEmpty &&
//			MPMediaLibrary.authorizationStatus() == .authorized
//	}
	var shouldRefreshDataAndViewsOnNextViewDidAppear = false
	var isAnimatingDuringRefreshTableView = 0
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setUp()
	}
	
	final func setUp() {
		beginObservingNotifications()
		setUpUI()
	}
	
	// LibraryTVC itself doesn't call this during viewDidLoad(), but its subclasses may want to.
	// Call this method late into launch, after we've already set up most of the UI; this method sets up the MediaPlayer-related functionality so that we can set up the rest of the UI (although this method itself doesn't set up the rest of the UI).
	// Before calling this, put the UI into the "Loading…" or "Updating…" state.
	final func integrateWithAndImportChangesFromMusicLibraryIfAuthorized() {
		MusicLibraryManager.shared.importChangesAndBeginGeneratingNotificationsIfAuthorized() // During a typical launch, we need to observe the notification after the import completes, so only do this after LibraryTVC's beginObservingNotifications(). After we observe that notification, we refresh our data and views, including the playback toolbar.
		PlayerControllerManager.setUpIfAuthorized() // This actually doesn't trigger refreshing the playback toolbar; refreshing after importing changes (above) does.
	}
	
	// MARK: Setting Up UI
	
	func setUpUI() {
		tableView.tableFooterView = UIView() // Removes the blank cells after the content ends. You can also drag in an empty View below the table view in the storyboard, but that also removes the separator below the last cell.
		
		refreshNavigationItemTitle()
		
		refreshAndSetBarButtons(animated: true) // So that when we open a Collection in "moving Albums" mode, the change is animated.
	}
	
	// Easy to override.
	func refreshNavigationItemTitle() {
	}
	
	// MARK: Setup Events
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if shouldRefreshDataAndViewsOnNextViewDidAppear {
			shouldRefreshDataAndViewsOnNextViewDidAppear = false
			refreshDataAndViews()
		}
	}
	
	// MARK: Teardown
	
	deinit {
		endObservingNotifications()
	}
	
	// MARK: - Accessing Data
	
	// WARNING: Never use sectionOfLibraryItems.items[indexPath.row]. That might return the wrong library item, because IndexPaths are offset by numberOfRowsInSectionAboveLibraryItems.
	// That's a hack to let us include other rows above the rows for library items. For example:
	// - Rows for album artwork and album info in SongsTVC.
	// - (Potentially in the future) in CollectionsTVC, rows for "All Albums" and "New Collection".
	// - (Potentially in the future) in Albums TVC, rows for "All Songs" and "Move Here".
	final func libraryItem(for indexPath: IndexPath) -> NSManagedObject {
		let indexOfLibraryItem = indexOfLibraryItem(for: indexPath)
		return sectionOfLibraryItems.items[indexOfLibraryItem] // Multisection: Get the right SectionOfLibraryItems.
	}
	
	final func indexOfLibraryItem(for indexPath: IndexPath) -> Int {
		return indexPath.row - numberOfRowsInSectionAboveLibraryItems
	}
	
	final func indexPaths(
		forIndexOfSectionOfLibraryItems indexOfSectionOfLibraryItems: Int
	) -> [IndexPath] {
		return tableView.indexPathsForRows(
			inSection: 0, // Multisection: Get the right SectionOfLibraryItems.
			firstRow: numberOfRowsInSectionAboveLibraryItems)
	}
	
	final func indexPathFor(
		indexOfLibraryItem: Int,
		indexOfSectionOfLibraryItem: Int
	) -> IndexPath {
		return IndexPath(
			row: indexOfLibraryItem + numberOfRowsInSectionAboveLibraryItems,
			section: indexOfSectionOfLibraryItem)
	}
	
	// MARK: - Refreshing Table View
	
	final func setItemsAndRefreshTableView(
		newItems: [NSManagedObject],
//		section: Int,
		completion: (() -> ())?
	) {
		let onscreenItems = sectionOfLibraryItems.items
		sectionOfLibraryItems.setItems(newItems)
		refreshTableView(
			onscreenItems: onscreenItems,
			completion: completion)
	}
	
	private func refreshTableView(
//		section: Int,
		onscreenItems: [NSManagedObject],
		completion: (() -> ())?
	) {
		let section = 0
		let newItems = sectionOfLibraryItems.items
		
		guard !newItems.isEmpty else {
			// Delete all rows, then exit.
			let allIndexPaths = tableView.allIndexPaths()
			isAnimatingDuringRefreshTableView += 1
			tableView.performBatchUpdates {
				tableView.deleteRows(at: allIndexPaths, with: .middle)
			} completion: { _ in
				self.isAnimatingDuringRefreshTableView -= 1
				if
					self.isAnimatingDuringRefreshTableView == 0, // See matching comment in performBatchUpdates below.
					!(self is CollectionsTVC)
				{
					self.performSegue(withIdentifier: "Removed All Contents", sender: nil)
				}
			}
			return
		}
		
		let (
			indexesOfOldItemsToDelete,
			indexesOfNewItemsToInsert,
			indexesOfItemsToMove
		) = SectionOfLibraryItems.indexesOfDeletesInsertsAndMoves(
			oldItems: onscreenItems,
			newItems: newItems)
		
		let indexPathsToDelete = indexesOfOldItemsToDelete.map {
			indexPathFor(
				indexOfLibraryItem: $0,
				indexOfSectionOfLibraryItem: section)
		}
		let indexPathsToInsert = indexesOfNewItemsToInsert.map {
			indexPathFor(
				indexOfLibraryItem: $0,
				indexOfSectionOfLibraryItem: section)
		}
		let indexPathsToMove = indexesOfItemsToMove.map {
			(indexPathFor(
				indexOfLibraryItem: $0,
				indexOfSectionOfLibraryItem: section),
			 indexPathFor(
				indexOfLibraryItem: $1,
				indexOfSectionOfLibraryItem: section))
		}
		
		isAnimatingDuringRefreshTableView += 1
		tableView.performBatchUpdates {
			tableView.deleteRows(at: indexPathsToDelete, with: .middle)
			tableView.insertRows(at: indexPathsToInsert, with: .middle)
			for (sourceIndexPath, destinationIndexPath) in indexPathsToMove {
				tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
			}
		} completion: { _ in
			self.isAnimatingDuringRefreshTableView -= 1
			if self.isAnimatingDuringRefreshTableView == 0 { // If we start multiple refreshes in quick succession, refreshes after the first one can beat the first one to the completion closure, because they don't have to animate anything in performBatchUpdates. This line of code lets us wait for the animations to finish before we execute the completion closure (once).
				completion?()
			}
		}
	}
	
	// MARK: - Refreshing Buttons
	
	final func refreshAndSetBarButtons(animated: Bool) {
		refreshBarButtons()
		
		// Set the navigation item buttons.
//		if isUpdating {
//			let activityIndicatorView = UIActivityIndicatorView()
//			activityIndicatorView.startAnimating()
//			let spinnerBarButtonItem = UIBarButtonItem(customView: activityIndicatorView)
//			navigationItem.setRightBarButtonItems([spinnerBarButtonItem], animated: animated)
//			return
//		}
		if isEditing {
			navigationItem.setLeftBarButtonItems(
				topLeftButtonsInEditingMode,
				animated: animated)
		} else {
			navigationItem.setLeftBarButtonItems(
				topLeftButtonsInViewingMode,
				animated: animated)
		}
		navigationItem.setRightBarButtonItems(
			topRightButtons,
			animated: animated)
		
		// Set the toolbar buttons.
		if isEditing {
			setToolbarItems(
				bottomButtonsInEditingMode,
				animated: animated)
		} else {
			setToolbarItems(
				bottomButtonsInViewingMode,
				animated: animated)
		}
	}
	
	func refreshBarButtons() {
		// There can momentarily be 0 library items if we're refreshing to reflect changes in the Music library.
		editButtonItem.isEnabled =
			MPMediaLibrary.authorizationStatus() == .authorized &&
			!sectionOfLibraryItems.items.isEmpty
		if isEditing {
			// "Sort"
			if sectionOfLibraryItems.items.isEmpty {
				sortButton.isEnabled = false
			} else {
				sortButton.isEnabled = shouldAllowSorting()
			}
			
			// "Move to Top"
			if sectionOfLibraryItems.items.isEmpty {
				floatToTopButton.isEnabled = false
			} else {
				floatToTopButton.isEnabled = shouldAllowFloating()
			}
			
			// "Move to Bottom"
			if sectionOfLibraryItems.items.isEmpty {
				sinkToBottomButton.isEnabled = false
			} else {
				sinkToBottomButton.isEnabled = shouldAllowSinking()
			}
		} else {
			refreshPlaybackToolbarButtons()
		}
	}
	
	// MARK: - Navigation
	
	final override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
		return !isEditing
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if
			segue.identifier == "Drill Down in Library",
			let libraryTVC = segue.destination as? LibraryTVC,
			let selectedIndexPath = tableView.indexPathForSelectedRow
		{
			libraryTVC.managedObjectContext = managedObjectContext
			let selectedItem = libraryItem(for: selectedIndexPath)
			libraryTVC.sectionOfLibraryItems = SectionOfLibraryItems(
				managedObjectContext: managedObjectContext,
				container: selectedItem,
				entityName: libraryTVC.entityName)
		}
		
		super.prepare(for: segue, sender: sender)
	}
	
}
