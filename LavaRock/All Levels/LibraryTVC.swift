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
		return CollectionsViewModel(
			context: mainContext,
			reflector: self)
	}()
	
	// Controls
	final var editingModeToolbarButtons = [UIBarButtonItem]()
	final var sortOptionsGrouped = [[SortOption]]()
	
	// MARK: Subclasses Can Optionally Customize
	
	// Controls
	final var viewingModeTopLeftButtons = [UIBarButtonItem]()
	private lazy var editingModeTopLeftButtons = [UIBarButtonItem.flexibleSpace()]
	final lazy var topRightButtons = [editButtonItem]
	final lazy var viewingModeToolbarButtons = playbackButtons
	
	// MARK: Subclasses Should Not Customize
	
	// Playback
	final var sharedPlayer: MPMusicPlayerController? { PlayerManager.player }
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
	final lazy var cancelMoveAlbumsButton: UIBarButtonItem = {
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
		
		reflectContainerTitles()
		
		setBarButtons(animated: true) // So that when we open a Collection in "moving Albums" mode, the change is animated.
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
		endObservingNotifications()
	}
	
	// MARK: - Setting Items and Refreshing
	
	// Easy to override. Overrides of this method should not call super (this implementation).
	func reflectNoItems() {
		deleteAllRowsThenExit()
	}
	
	// Deletes all rows, including any rows not for library items, then performs an unwind segue.
	// For AlbumsTVC and SongsTVC only; not for CollectionsTVC, because it doesn't have a "Removed All Contents" segue.
	private func deleteAllRowsThenExit() {
		let allIndexPaths = tableView.allIndexPaths()
		
		isAnimatingDuringSetItemsAndRefresh += 1
		tableView.performBatchUpdates {
			tableView.deleteRows(at: allIndexPaths, with: .middle)
		} completion: { _ in
			self.isAnimatingDuringSetItemsAndRefresh -= 1
			if self.isAnimatingDuringSetItemsAndRefresh == 0 { // See corresponding comment in setItemsAndMoveRows.
				self.dismiss(animated: true) { // If we moved all the Albums out of a Collection, we need to wait until we've completely dismissed the "move Albums to…" sheet before we exit. Otherwise, we'll fail to exit and get trapped in a blank AlbumsTVC.
					self.performSegue(
						withIdentifier: "Removed All Contents",
						sender: nil)
				}
			}
		}
		
		didChangeRowsOrSelectedRows() // Do this before the completion closure, so that we disable all the editing buttons during the animation.
	}
	
	final func setItemsAndMoveRows(
		newItems: [NSManagedObject],
		thenSelect toSelect: [IndexPath] = [],
		section: Int,
		completion: (() -> Void)? = nil
	) {
		let oldItems = viewModel.group(forSection: section).items
		let changes = oldItems.indicesOfChanges(toMatch: newItems) { oldItem, newItem in
			oldItem.objectID == newItem.objectID
		}
		
		let indexOfGroup = viewModel.indexOfGroup(forSection: section)
		
		viewModel.groups[indexOfGroup].setItems(newItems)
		
		guard !newItems.isEmpty else {
			reflectNoItems()
			return
		}
		
		let toDelete = changes.deletes.map {
			viewModel.indexPathFor(indexOfItemInGroup: $0, indexOfGroup: indexOfGroup)
		}
		let toInsert = changes.inserts.map {
			viewModel.indexPathFor(indexOfItemInGroup: $0, indexOfGroup: indexOfGroup)
		}
		let toMove = changes.moves.map { oldIndex, newIndex in
			(viewModel.indexPathFor(indexOfItemInGroup: oldIndex, indexOfGroup: indexOfGroup),
			 viewModel.indexPathFor(indexOfItemInGroup: newIndex, indexOfGroup: indexOfGroup))
		}
		
		isAnimatingDuringSetItemsAndRefresh += 1
		tableView.performBatchUpdates {
			tableView.deleteRows(at: toDelete, with: .middle)
			tableView.insertRows(at: toInsert, with: .middle)
			toMove.forEach { sourceIndexPath, destinationIndexPath in
				tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
			}
		} completion: { _ in
			self.isAnimatingDuringSetItemsAndRefresh -= 1
			if self.isAnimatingDuringSetItemsAndRefresh == 0 { // If we start multiple refreshes in quick succession, refreshes after the first one can beat the first one to the completion closure, because they don't have to animate anything in performBatchUpdates. This line of code lets us wait for the animations to finish before we execute the completion closure (once).
				completion?()
			}
		}
		
		// Do this after performBatchUpdates's main closure, because otherwise it doesn't work on newly inserted rows.
		// This method should do this so that callers don't need to call didChangeRowsOrSelectedRows.
		toSelect.forEach {
			tableView.selectRow(at: $0, animated: false, scrollPosition: .none)
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
		
		editButtonItem.isEnabled = allowsEdit()
		
		sortButton.isEnabled = allowsSort()
		floatToTopButton.isEnabled = allowsFloat()
		sinkToBottomButton.isEnabled = allowsSink()
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
			return viewModel.groups.count == 1
		} else {
			return selectedIndexPaths.isContiguousWithinSameSection()
		}
	}
	
	private func allowsFloat() -> Bool {
		guard !viewModel.isEmpty() else {
			return false
		}
		
		let selectedIndexPaths = tableView.indexPathsForSelectedRowsNonNil
		if selectedIndexPaths.isEmpty {
			return false
		} else {
			return selectedIndexPaths.isWithinSameSection()
		}
	}
	
	private func allowsSink() -> Bool {
		return allowsFloat()
	}
	
	// MARK: - Navigation
	
	final override func shouldPerformSegue(
		withIdentifier identifier: String,
		sender: Any?
	) -> Bool {
		return !isEditing
	}
	
}
