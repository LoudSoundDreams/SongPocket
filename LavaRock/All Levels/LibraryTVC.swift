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
	PlaybackController
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
	var editingModeToolbarButtons = [UIBarButtonItem]()
	var sortOptionGroups = [[SortOption]]()
	
	// "Constants" that subclasses can optionally customize
	var managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext // Replace this with a child context when in "moving Albums" mode.
	var numberOfRowsInSectionAboveLibraryItems = 0
	var viewingModeTopLeftButtons = [UIBarButtonItem]()
	private lazy var editingModeTopLeftButtons = [UIBarButtonItem.flexibleSpac3()]
	lazy var topRightButtons = [editButtonItem]
	lazy var viewingModeToolbarButtons = playbackButtons
	
	// "Constants" that subclasses should not change
	var sharedPlayer: MPMusicPlayerController? { PlayerManager.player }
	let cellReuseIdentifier = "Cell"
	lazy var noItemsPlaceholderView = {
		return tableView?.dequeueReusableCell(withIdentifier: "No Items Placeholder") // Every subclass needs a placeholder cell in the storyboard with this reuse identifier.
	}()
	lazy var sortButton: UIBarButtonItem = {
		if #available(iOS 14, *) {
			return UIBarButtonItem(
				title: LocalizedString.sort,
				menu: sortOptionsMenu())
		} else { // iOS 13
			return UIBarButtonItem(
				title: LocalizedString.sort,
				style: .plain,
				target: self,
				action: #selector(showSortOptionsActionSheet))
		}
	}()
	lazy var moveToTopOrBottomButton: UIBarButtonItem = {
		let image = UIImage(systemName: "arrow.up.arrow.down")
		let button: UIBarButtonItem = {
			if #available(iOS 14, *) {
				return UIBarButtonItem(
					image: image,
					menu: moveToTopOrBottomMenu())
			} else { // iOS 13
				return UIBarButtonItem(
					image: image,
					style: .plain,
					target: self,
					action: #selector(showMoveToTopOrBottomActionSheet))
			}
		}()
		button.accessibilityLabel = "Move to top or bottom" // TO DO: Localize
		return button
	}()
	lazy var floatToTopButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			image: UIImage.floatToTopSymbol,
			style: .plain,
			target: self,
			action: #selector(floatSelectedItemsToTopOfSection))
		button.accessibilityLabel = LocalizedString.moveToTop
		return button
	}()
	lazy var sinkToBottomButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			image: UIImage.sinkToBottomSymbol,
			style: .plain,
			target: self,
			action: #selector(sinkSelectedItemsToBottomOfSection))
		button.accessibilityLabel = LocalizedString.moveToBottom
		return button
	}()
	lazy var cancelMoveAlbumsButton = UIBarButtonItem(
		barButtonSystemItem: .cancel,
		target: self,
		action: #selector(cancelMoveAlbums))
	@objc private func cancelMoveAlbums() {
		dismiss(animated: true)
	}
	
	// "Constants" that subclasses should not change, for PlaybackController
	final lazy var playbackButtons = [
		previousSongButton,
		.flexibleSpac3(),
		rewindButton,
		.flexibleSpac3(),
		playPauseButton,
		.flexibleSpac3(),
		nextSongButton,
	]
	final lazy var previousSongButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			image: UIImage(systemName: "backward.end.fill"),
			style: .plain,
			target: self,
			action: #selector(goToPreviousSong))
		button.width = 10.0 //
		button.accessibilityLabel = LocalizedString.previousTrack
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	final lazy var rewindButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			image: UIImage(systemName: "arrow.counterclockwise.circle.fill"),
			style: .plain,
			target: self,
			action: #selector(rewind))
		button.width = 10.0 //
		button.accessibilityLabel = LocalizedString.restart
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	final let playImage = UIImage(systemName: "play.fill")
	final let playAction = #selector(play)
	final let playAccessibilityLabel = LocalizedString.play
	final let playButtonAdditionalAccessibilityTraits: UIAccessibilityTraits = .startsMediaSession
	final lazy var playPauseButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			image: playImage,
			style: .plain,
			target: self,
			action: playAction)
		button.width = 10.0 // As of iOS 14.2 beta 4, even when you set the width of each button manually, the "pause.fill" button is still narrower than the "play.fill" button.
		button.accessibilityLabel = playAccessibilityLabel
		button.accessibilityTraits.formUnion(playButtonAdditionalAccessibilityTraits)
		return button
	}()
	final lazy var nextSongButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			image: UIImage(systemName: "forward.end.fill"),
			style: .plain,
			target: self,
			action: #selector(goToNextSong))
		button.width = 10.0 //
		button.accessibilityLabel = LocalizedString.nextTrack
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	
	// MARK: Variables
	
	lazy var sectionOfLibraryItems: SectionOfLibraryItems
	= SectionOfCollectionsOrAlbums( // Default value for CollectionsTVC
		entityName: entityName,
		managedObjectContext: managedObjectContext,
		container: nil)
	var isImportingChanges = false
	var needsRefreshLibraryItemsOnViewDidAppear = false
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
	
	// MARK: Setting Up UI
	
	func setUpUI() {
		if #available(iOS 15, *) {
			// In iOS 15, by default, tableView.fillerRowHeight is 0, which removes the blank rows below the last row.
			// Xcode 12
			tableView.tableFooterView = UIView()
		} else {
			tableView.tableFooterView = UIView() // Removes the blank rows below the last row.
			// You can also drag in an empty View below the table view in the storyboard, but that also removes the separator below the last cell.
		}
		
		refreshNavigationItemTitle()
		
		setBarButtons(animated: true) // So that when we open a Collection in "moving Albums" mode, the change is animated.
	}
	
	// Easy to override.
	func refreshNavigationItemTitle() {
	}
	
	// MARK: Setup Events
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if needsRefreshLibraryItemsOnViewDidAppear {
			needsRefreshLibraryItemsOnViewDidAppear = false
			refreshLibraryItems()
		}
	}
	
	// MARK: Teardown
	
	deinit {
		endObservingNotifications()
	}
	
	// MARK: - Accessing Data
	
	// WARNING: Never use sectionOfLibraryItems.items[indexPath.row]. That might return the wrong library item, because IndexPaths are offset by numberOfRowsInSectionAboveLibraryItems.
	// That's a hack to let us include rows for album artwork and album info in SongsTVC, above the rows for library items.
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
	
	// Deletes all rows, including any rows not for library items, then performs an unwind segue.
	private func deleteAllRowsThenExit() {
		let allIndexPaths = tableView.allIndexPaths()
		
		isAnimatingDuringRefreshTableView += 1
		tableView.performBatchUpdates {
			tableView.deleteRows(at: allIndexPaths, with: .middle)
		} completion: { _ in
			self.isAnimatingDuringRefreshTableView -= 1
			if
				self.isAnimatingDuringRefreshTableView == 0, // See matching comment in setItemsAndRefreshTableView.
				!(self is CollectionsTVC)
			{
				self.dismiss(animated: true) { // If we moved all the Albums out of a Collection, we need to wait until we've completely dismissed the "move Albums to…" sheet before we exit. Otherwise, we'll fail to exit and get trapped in a blank AlbumsTVC.
					self.performSegue(
						withIdentifier: "Removed All Contents",
						sender: nil)
				}
			}
		}
		
		didChangeRowsOrSelectedRows() // Do this before the completion closure, so that we disable all the editing buttons during the animation.
	}
	
	final func setItemsAndRefreshTableView(
//		section: Int,
		newItems: [NSManagedObject],
		indexesOfNewItemsToSelect: [Int] = [Int](),
		completion: (() -> ())? = nil
	) {
		let section = 0
		
		let oldItems = sectionOfLibraryItems.items
		let changes = oldItems.indexesOfChanges(toMatch: newItems) { oldItem, newItem in
			oldItem.objectID == newItem.objectID
		}
		
		sectionOfLibraryItems.setItems(newItems)
		
		guard !newItems.isEmpty else {
			deleteAllRowsThenExit()
			return
		}
		
		let indexPathsToDelete = changes.deletes.map {
			indexPathFor(
				indexOfLibraryItem: $0,
				indexOfSectionOfLibraryItem: section)
		}
		let indexPathsToInsert = changes.inserts.map {
			indexPathFor(
				indexOfLibraryItem: $0,
				indexOfSectionOfLibraryItem: section)
		}
		let indexPathsToMove = changes.moves.map { oldIndex, newIndex in
			(indexPathFor(
				indexOfLibraryItem: oldIndex,
				indexOfSectionOfLibraryItem: section),
			 indexPathFor(
				indexOfLibraryItem: newIndex,
				indexOfSectionOfLibraryItem: section))
		}
		
		let indexPathsToSelect = indexesOfNewItemsToSelect.map {
			indexPathFor(
				indexOfLibraryItem: $0,
				indexOfSectionOfLibraryItem: section)
		}
		
		isAnimatingDuringRefreshTableView += 1
		tableView.performBatchUpdates {
			tableView.deleteRows(at: indexPathsToDelete, with: .middle)
			tableView.insertRows(at: indexPathsToInsert, with: .middle)
			indexPathsToMove.forEach { sourceIndexPath, destinationIndexPath in
				tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
			}
		} completion: { _ in
			self.isAnimatingDuringRefreshTableView -= 1
			if self.isAnimatingDuringRefreshTableView == 0 { // If we start multiple refreshes in quick succession, refreshes after the first one can beat the first one to the completion closure, because they don't have to animate anything in performBatchUpdates. This line of code lets us wait for the animations to finish before we execute the completion closure (once).
				completion?()
			}
		}
		
		indexPathsToSelect.forEach {
			tableView.selectRow( // Do this after performBatchUpdates's main closure, because otherwise it doesn't work on newly inserted rows.
				at: $0,
				animated: false,
				scrollPosition: .none)
		}
		
		didChangeRowsOrSelectedRows()
	}
	
	// MARK: - Refreshing Buttons
	
	final func setBarButtons(animated: Bool) {
		refreshEditingButtons()
		navigationItem.setRightBarButtonItems(
			topRightButtons,
			animated: animated)
		
		if isEditing {
			navigationItem.setLeftBarButtonItems(
				editingModeTopLeftButtons,
				animated: animated)
			setToolbarItems(
				editingModeToolbarButtons,
				animated: animated)
		} else {
			navigationItem.setLeftBarButtonItems(
				viewingModeTopLeftButtons,
				animated: animated)
			
			refreshPlaybackButtons()
			setToolbarItems(
				viewingModeToolbarButtons,
				animated: animated)
		}
	}
	
	// For clarity, call this rather than refreshEditingButtons directly, whenever appropriate.
	final func didChangeRowsOrSelectedRows() {
		refreshEditingButtons()
	}
	
	func refreshEditingButtons() {
		// There can momentarily be 0 library items if we're refreshing to reflect changes in the Music library.
		
		editButtonItem.isEnabled = !sectionOfLibraryItems.isEmpty()
		
		sortButton.isEnabled = allowsSort()
		moveToTopOrBottomButton.isEnabled = allowsMoveToTopOrBottom()
		floatToTopButton.isEnabled = allowsFloat()
		sinkToBottomButton.isEnabled = allowsSink()
	}
	
	// MARK: - Navigation
	
	final override func shouldPerformSegue(
		withIdentifier identifier: String,
		sender: Any?
	) -> Bool {
		return !isEditing
	}
	
	override func prepare(
		for segue: UIStoryboardSegue,
		sender: Any?
	) {
		if
			segue.identifier == "Drill Down in Library",
			let libraryTVC = segue.destination as? LibraryTVC,
			let selectedIndexPath = tableView.indexPathForSelectedRow
		{
			libraryTVC.managedObjectContext = managedObjectContext
			let selectedItem = libraryItem(for: selectedIndexPath)
			libraryTVC.sectionOfLibraryItems = SectionOfCollectionsOrAlbums(
				entityName: libraryTVC.entityName,
				managedObjectContext: managedObjectContext,
				container: selectedItem)
		}
		
		super.prepare(for: segue, sender: sender)
	}
	
}
