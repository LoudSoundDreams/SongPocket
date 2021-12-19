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
	
	enum SortOption: CaseIterable {
		// For Collections only
		case title
		
		// For Albums only
		case newestFirst
		case oldestFirst
		
		// For Songs only
		case trackNumber
		
		// For all types
		case random
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
			case .random:
				return LocalizedString.random
			case .reverse:
				return LocalizedString.reverse
			}
		}
		
		init?(localizedName: String) {
			guard let matchingCase = Self.allCases.first(where: {
				$0.localizedName() == localizedName
			}) else {
				return nil
			}
			self = matchingCase
		}
	}
	
	// MARK: - Properties
	
	// MARK: Subclasses Should Customize
	
	// Data
	final lazy var viewModel: LibraryViewModel = { // Default value for CollectionsTVC
		let mainContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
		return CollectionsViewModel(
			context: mainContext,
			prerowsInEachSection: [])
	}()
	
	// Controls
	final var editingModeToolbarButtons: [UIBarButtonItem] = []
	final var sortOptionsGrouped: [[SortOption]] = []
	
	// MARK: Subclasses Can Optionally Customize
	
	// Controls
	final var viewingModeTopLeftButtons: [UIBarButtonItem] = []
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
		menu: makeSortOptionsMenu())
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
		
		setBarButtons(animated: true) // So that when we open a Collection in the "move albums" sheet, the change is animated.
		
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
		reloading toReload: [IndexPath] = [],
		thenSelect toSelect: Set<IndexPath> = [], // TO DO: Don't require a `Set` here.
		completion: (() -> Void)? = nil
	) {
		let oldViewModel = viewModel
		
		viewModel = newViewModel
		
		guard !newViewModel.isEmpty() else {
			reflectViewModelIsEmpty()
			return
		}
		
		let oldSections = oldViewModel.sectionStructures()
		let newSections = newViewModel.sectionStructures()
		let sectionBatchUpdates = oldSections.differenceInferringMoves(toMatch: newSections) {
			oldSection, newSection in
			oldSection.identifier == newSection.identifier
		}.batchUpdates()
		
		let oldSectionIdentifiersAndIndices = zip(
			oldSections.map { $0.identifier },
			oldSections.indices)
		let oldSectionIndicesByIdentifier = Dictionary(
			uniqueKeysWithValues: oldSectionIdentifiersAndIndices)
		var rowBatchUpdates: [BatchUpdates<IndexPath>] = []
		newSections.indices.forEach { newSectionIndex in
			let sectionIdentifier = newSections[newSectionIndex].identifier
			// We never delete, insert, or move rows into or out of deleted or inserted sections, because when we delete or insert sections, we also delete or insert all the rows within them.
			// We also never move rows between sections with different identifiers, because we only compare sections with equivalent identifiers.
			guard let oldSectionIndex = oldSectionIndicesByIdentifier[sectionIdentifier] else { return }
			let oldRowIdentifiers = oldSections[oldSectionIndex].rowIdentifiers
			
			let newRowIdentifiers = newSections[newSectionIndex].rowIdentifiers
			
			let rowBatchUpdatesInSection = batchUpdatesOfRows(
				oldSection: oldSectionIndex,
				oldIdentifiers: oldRowIdentifiers,
				newSection: newSectionIndex,
				newIdentifiers: newRowIdentifiers)
			rowBatchUpdates.append(rowBatchUpdatesInSection)
		}
		
		isAnimatingDuringSetItemsAndRefresh += 1
		tableView.performBatchUpdates(
			sections: sectionBatchUpdates,
			rows: rowBatchUpdates,
			movingWith: .middle,
			reloading: toReload,
			reloadingWith: .fade
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
	
	private func batchUpdatesOfRows<Identifier: Hashable>(
		oldSection: Int,
		oldIdentifiers: [Identifier],
		newSection: Int,
		newIdentifiers: [Identifier]
	) -> BatchUpdates<IndexPath> {
		let updates = oldIdentifiers.differenceInferringMoves(
			toMatch: newIdentifiers,
			by: ==)
			.batchUpdates()
		
		let toDelete = updates.toDelete.map { IndexPath(row: $0, section: oldSection) }
		let toInsert = updates.toInsert.map { IndexPath(row: $0, section: newSection) }
		let toMove = updates.toMove.map { (oldRow, newRow) in
			(IndexPath(row: oldRow, section: oldSection),
			 IndexPath(row: newRow, section: newSection))
		}
		return BatchUpdates(
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
				self.dismiss(animated: true) { // If we moved all the Albums out of a Collection, we need to wait until we've completely dismissed the "move albums" sheet before we exit. Otherwise, we'll fail to exit and get trapped in a blank AlbumsTVC.
					self.performSegue(withIdentifier: "Removed All Contents", sender: self)
				}
			}
		}
		
		didChangeRowsOrSelectedRows()
	}
	
	final func refreshNavigationItemTitle() {
		title = viewModel.bigTitle()
	}
	
	func showToolbar() {
		navigationController?.toolbar.isHidden = false
	}
	
	func hideToolbar() {
		navigationController?.toolbar.isHidden = true
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
			return viewModel.viewContainerIsSpecific()
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
