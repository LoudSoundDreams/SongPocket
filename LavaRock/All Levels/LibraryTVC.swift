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

class LibraryTVC: UITableViewController {
	
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
	
	// MARK: Subclasses Should Customize
	
	// Data
	final lazy var viewModel: LibraryViewModel = { // Default value for CollectionsTVC
		let mainContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
		return CollectionsViewModel(context: mainContext)
	}()
	
	// Controls
	final var editingModeToolbarButtons = [UIBarButtonItem]()
	final var sortOptionsGrouped = [[SortOption]]()
	
	// MARK: Subclasses Can Optionally Customize
	
	// Controls
	final var viewingModeTopLeftButtons = [UIBarButtonItem]()
	private lazy var editingModeTopLeftButtons = [UIBarButtonItem.flexibleSpace()]
	final lazy var topRightButtons = [editButtonItem]
	final lazy var viewingModeToolbarButtons = FeatureFlag.tabBar ? editingModeToolbarButtons : playbackButtons
	
	// MARK: Subclasses Should Not Customize
	
	// Playback
	final lazy var playbackButtons = [
		previousSongButton, .flexibleSpace(),
		rewindButton, .flexibleSpace(),
		playPauseButton, .flexibleSpace(),
		nextSongButton,
	]
	final lazy var previousSongButton: UIBarButtonItem = {
		let action = UIAction { _ in self.goToPreviousSong() }
		let button = UIBarButtonItem(
			image: UIImage(systemName: "backward.end.fill"),
			primaryAction: action)
		button.accessibilityLabel = LocalizedString.previousTrack
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	final lazy var rewindButton: UIBarButtonItem = {
		let action = UIAction { _ in self.rewind() }
		let button = UIBarButtonItem(
			image: UIImage(systemName: "arrow.counterclockwise.circle.fill"),
			primaryAction: action)
		button.accessibilityLabel = LocalizedString.restart
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	final lazy var playPauseButton = UIBarButtonItem()
	final lazy var nextSongButton: UIBarButtonItem = {
		let action = UIAction { _ in self.goToNextSong() }
		let button = UIBarButtonItem(
			image: UIImage(systemName: "forward.end.fill"),
			primaryAction: action)
		button.accessibilityLabel = LocalizedString.nextTrack
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	
	// Controls
	final lazy var sortButton = UIBarButtonItem(
		title: LocalizedString.sort,
		menu: sortOptionsMenu())
	final lazy var floatToTopButton: UIBarButtonItem = {
		let action = UIAction { _ in self.floatSelectedItemsToTopOfSection() }
		let button = UIBarButtonItem(
			image: UIImage.floatToTopSymbol,
			primaryAction: action)
		button.accessibilityLabel = LocalizedString.moveToTop
		return button
	}()
	final lazy var sinkToBottomButton: UIBarButtonItem = {
		let action = UIAction { _ in self.sinkSelectedItemsToBottomOfSection() }
		let button = UIBarButtonItem(
			image: UIImage.sinkToBottomSymbol,
			primaryAction: action)
		button.accessibilityLabel = LocalizedString.moveToBottom
		return button
	}()
	final lazy var cancelAndDismissButton: UIBarButtonItem = {
		let action = UIAction { _ in self.dismiss(animated: true) }
		return UIBarButtonItem(
			systemItem: .cancel,
			primaryAction: action)
	}()
	
	// State
	final var isImportingChanges = false
	final var needsRefreshLibraryItemsOnViewDidAppear = false
	final var isAnimatingDuringSetItemsAndRefresh = 0
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setUpPlaybackStateReflecting()
		
		setUp()
	}
	
	final func setUp() {
		beginObservingNotifications()
		setUpUI()
	}
	
	func setUpUI() {
		if #available(iOS 15, *) {
			// In iOS 15, by default, tableView.fillerRowHeight is 0, which removes the blank rows below the last row.
		} else {
			tableView.tableFooterView = UIView() // Removes the blank rows below the last row.
			// You can also drag in an empty View below the table view in the storyboard, but that also removes the separator below the last cell.
		}
		
		refreshNavigationItemTitle()
		
		setBarButtons(animated: true) // So that when we open a Collection in "moving Albums" mode, the change is animated.
		
		if FeatureFlag.tabBar {
			hideToolbar()
		}
	}
	
	// MARK: Setup Events
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if needsRefreshLibraryItemsOnViewDidAppear {
			needsRefreshLibraryItemsOnViewDidAppear = false
			refreshLibraryItems()
		}
	}
	
	// MARK: - Teardown
	
	deinit {
		endObservingPlaybackStateChanges()
		
		NotificationCenter.default.removeObserver(self)
	}
	
	// MARK: - Setting Items
	
	final func setViewModelAndMoveRows(
		_ newViewModel: LibraryViewModel,
		andSelectRowsAt toSelect: Set<IndexPath> = [],
		completion: (() -> Void)? = nil
	) {
		guard !newViewModel.isEmpty() else {
			viewModel = newViewModel
			reflectViewModelIsEmpty()
			return
		}
		
		let newGroups = newViewModel.groups
		
		let oldViewModel = viewModel
		let oldGroups = oldViewModel.groups
		let updatesOfGroups: BatchUpdates<Int>?
		let reorderedOldGroups: [GroupOfLibraryItems]
		if
			viewModel is CollectionsViewModel
		{
			updatesOfGroups = nil
			reorderedOldGroups = oldGroups
		} else if
			let albumsViewModel = oldViewModel as? AlbumsViewModel,
			let oldGroups = oldGroups as? [GroupOfCollectionsOrAlbums],
			let newGroups = newGroups as? [GroupOfCollectionsOrAlbums]
		{
			let differenceOfGroups = albumsViewModel.differenceOfGroupsInferringMoves(
				toMatch: newGroups)
			updatesOfGroups = differenceOfGroups.batchUpdates()
			reorderedOldGroups = oldGroups.applying(differenceOfGroups)!
		} else if
			let songsViewModel = oldViewModel as? SongsViewModel,
			let oldGroups = oldGroups as? [GroupOfSongs],
			let newGroups = newGroups as? [GroupOfSongs]
		{
			let differenceOfGroups = songsViewModel.differenceOfGroupsInferringMoves(
				toMatch: newGroups)
			updatesOfGroups = differenceOfGroups.batchUpdates()
			reorderedOldGroups = oldGroups.applying(differenceOfGroups)!
		} else {
			fatalError("`LibraryTVC` with an unknown type for `viewModel` called `setViewModelAndMoveRows`.")
		}
		
		let oldNumberOfSectionsAbove = type(of: oldViewModel).numberOfSectionsAboveLibraryItems
		let newNumberOfSectionsAbove = type(of: newViewModel).numberOfSectionsAboveLibraryItems
		let sectionsToDelete = updatesOfGroups?.toDelete.map { oldNumberOfSectionsAbove + $0 } ?? []
		let sectionsToInsert = updatesOfGroups?.toInsert.map { newNumberOfSectionsAbove + $0 } ?? []
		let sectionsToMove = updatesOfGroups?.toMove.map { (oldIndex, newIndex) in
			(oldNumberOfSectionsAbove + oldIndex,
			 newNumberOfSectionsAbove + newIndex)
		} ?? []
		
		viewModel = newViewModel
		
		var rowsToDelete = [IndexPath]()
		var rowsToInsert = [IndexPath]()
		var rowsToMove = [(IndexPath, IndexPath)]()
		let tuplesForContainersAndOldIndicesOfGroups: [(NSManagedObject?, Int)]
		= oldGroups.indices.map {
			let oldGroup = oldGroups[$0]
			return (
				oldGroup.container, // Yes, you can use `nil` as a `Dictionary` key.
				$0
			)
		}
		let oldIndicesOfGroupsByContainer = Dictionary(
			uniqueKeysWithValues: tuplesForContainersAndOldIndicesOfGroups)
		newGroups.indices.reversed().forEach { newIndexOfGroup in
			let newGroup = newGroups[newIndexOfGroup]
			
			let oldItems = reorderedOldGroups[newIndexOfGroup].items
			let container = newGroup.container // Is `nil` if we're inserting a new group
			let oldIndexOfGroup = oldIndicesOfGroupsByContainer[container]
			
			let newItems = newGroup.items
			
			let updates = batchUpdatesOfRows(
				oldItems: oldItems,
				oldIndexOfGroup: oldIndexOfGroup,
				newItems: newItems,
				newIndexOfGroup: newIndexOfGroup)
			rowsToDelete.append(contentsOf: updates.toDelete)
			rowsToInsert.append(contentsOf: updates.toInsert)
			rowsToMove.append(contentsOf: updates.toMove)
		}
		
		isAnimatingDuringSetItemsAndRefresh += 1
		tableView.performBatchUpdates(
			deletingSections: sectionsToDelete,
			deletingRows: rowsToDelete,
			insertingSections: sectionsToInsert,
			insertingRows: rowsToInsert,
			movingSections: sectionsToMove,
			movingRows: rowsToMove
		) {
			self.isAnimatingDuringSetItemsAndRefresh -= 1
			if self.isAnimatingDuringSetItemsAndRefresh == 0 { // If we start multiple refreshes in quick succession, refreshes after the first one can beat the first one to the completion closure, because they don't have to animate anything in performBatchUpdates. This line of code lets us wait for the animations to finish before we execute the completion closure (once).
				completion?()
			}
		}
		
		tableView.indexPathsForSelectedRowsNonNil.forEach {
			if !toSelect.contains($0) {
				tableView.deselectRow(at: $0, animated: true)
			}
		}
		toSelect.forEach {
			// Do this after `performBatchUpdates`’s main closure, because otherwise it doesn’t work on newly inserted rows.
			// This method should do this so that callers don’t need to call `didChangeRowsOrSelectedRows`.
			tableView.selectRow(at: $0, animated: false, scrollPosition: .none)
		}
		
		didChangeRowsOrSelectedRows()
	}
	
	// WARNING: You must update `viewModel` first.
	private func batchUpdatesOfRows(
		oldItems: [NSManagedObject],
		oldIndexOfGroup: Int?,
		newItems: [NSManagedObject],
		newIndexOfGroup: Int
	) -> BatchUpdates<IndexPath> {
		let updatesOfIndicesOfItems = oldItems.batchUpdates(
			toMatch: newItems
		) { oldItem, newItem in
			oldItem.objectID == newItem.objectID
		}
		
		let toDelete: [IndexPath] = updatesOfIndicesOfItems.toDelete.compactMap {
			guard let oldIndexOfGroup = oldIndexOfGroup else {
				return nil
			}
			return type(of: viewModel).indexPathFor(
				indexOfItemInGroup: $0,
				indexOfGroup: oldIndexOfGroup)
		}
		let toInsert = updatesOfIndicesOfItems.toInsert.map {
			type(of: viewModel).indexPathFor(
				indexOfItemInGroup: $0,
				indexOfGroup: newIndexOfGroup)
		}
		let toMove: [(IndexPath, IndexPath)] = updatesOfIndicesOfItems.toMove.compactMap { (oldIndex, newIndex) in
			guard let oldIndexOfGroup = oldIndexOfGroup else {
				return nil
			}
			return (
				type(of: viewModel).indexPathFor(
					indexOfItemInGroup: oldIndex,
					indexOfGroup: oldIndexOfGroup),
				type(of: viewModel).indexPathFor(
					indexOfItemInGroup: newIndex,
					indexOfGroup: newIndexOfGroup)
			)
		}
		
		return BatchUpdates<IndexPath>(
			toDelete: toDelete,
			toInsert: toInsert,
			toMove: toMove)
	}
	
	// MARK: - Refreshing UI
	
	func reflectViewModelIsEmpty() {
		fatalError()
	}
	
	// `LibraryTVC` itself doesn't call this, but its subclasses might want to.
	final func deleteThenExit(sections toDelete: [Int]) {
		tableView.deselectAllRows(animated: true)
		
		isAnimatingDuringSetItemsAndRefresh += 1
		tableView.performBatchUpdates {
			tableView.deleteSections(IndexSet(toDelete), with: .middle)
		} completion: { _ in
			self.isAnimatingDuringSetItemsAndRefresh -= 1
			if self.isAnimatingDuringSetItemsAndRefresh == 0 { // See corresponding comment in setItemsAndMoveRows.
				self.dismiss(animated: true) { // If we moved all the Albums out of a Collection, we need to wait until we've completely dismissed the "move albums to…" sheet before we exit. Otherwise, we'll fail to exit and get trapped in a blank AlbumsTVC.
					self.performSegue(withIdentifier: "Removed All Contents", sender: self)
				}
			}
		}
		
		didChangeRowsOrSelectedRows() // Do this before the completion closure, so that we disable all the editing buttons during the animation.
	}
	
	final func refreshNavigationItemTitle() {
		title = viewModel.navigationItemTitle
	}
	
	func showToolbar() {
		navigationController?.isToolbarHidden = false
//		navigationController?.toolbar.isHidden = false
	}
	
	func hideToolbar() {
		navigationController?.isToolbarHidden = true
//		navigationController?.toolbar.isHidden = true
	}
	
	final func setBarButtons(animated: Bool) {
		refreshEditingButtons()
		navigationItem.setRightBarButtonItems(topRightButtons, animated: animated)
		
		if isEditing {
			navigationItem.setLeftBarButtonItems(editingModeTopLeftButtons, animated: animated)
			setToolbarItems(editingModeToolbarButtons, animated: animated)
		} else {
			navigationItem.setLeftBarButtonItems(viewingModeTopLeftButtons, animated: animated)
			
			refreshPlaybackButtons()
			setToolbarItems(viewingModeToolbarButtons, animated: animated)
		}
	}
	
	final func didChangeRowsOrSelectedRows() {
		refreshEditingButtons()
	}
	
	// Overrides should call super (this implementation).
	func refreshEditingButtons() {
		// There can momentarily be 0 library items if we're refreshing to reflect changes in the Music library.
		
		editButtonItem.isEnabled = allowsEdit()
		
		sortButton.isEnabled = allowsSort()
		floatToTopButton.isEnabled = allowsFloatAndSink()
		sinkToBottomButton.isEnabled = allowsFloatAndSink()
	}
	
	private func allowsEdit() -> Bool {
		return !viewModel.isEmpty()
	}
	
	// You should only be allowed to sort contiguous items within the same GroupOfLibraryItems.
	private func allowsSort() -> Bool {
		guard !viewModel.isEmpty() else {
			return false
		}
		let selectedIndexPaths = tableView.indexPathsForSelectedRowsNonNil
		if selectedIndexPaths.isEmpty {
			return viewModel.viewContainerIsSpecific
		} else {
			return selectedIndexPaths.isContiguousWithinEachSection()
		}
	}
	
	private func allowsFloatAndSink() -> Bool {
		guard !viewModel.isEmpty() else {
			return false
		}
		let selectedIndexPaths = tableView.indexPathsForSelectedRowsNonNil
		if selectedIndexPaths.isEmpty {
			return false
		} else {
			return true
		}
	}
	
	// MARK: - Navigation
	
	final override func shouldPerformSegue(
		withIdentifier identifier: String,
		sender: Any?
	) -> Bool {
		return !isEditing
	}
	
}
