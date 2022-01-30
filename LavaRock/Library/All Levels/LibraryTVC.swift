//
//  LibraryTVC.swift
//  LavaRock
//
//  Created by h on 2020-04-15.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import CoreData

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
				localizedName == $0.localizedName()
			}) else {
				return nil
			}
			self = matchingCase
		}
	}
	
	// MARK: - Properties
	
	// MARK: Subclasses Should Customize
	
	// Data
	final lazy var viewModel: LibraryViewModel = CollectionsViewModel(
		context: Persistence.viewContext,
		prerowsInEachSection: [])
	
	// Controls
	final var editingModeToolbarButtons: [UIBarButtonItem] = []
	final var sortOptionsGrouped: [[SortOption]] = []
	
	// MARK: Subclasses Can Optionally Customize
	
	// Controls
	final var viewingModeTopLeftButtons: [UIBarButtonItem] = []
	private lazy var editingModeTopLeftButtons: [UIBarButtonItem] = [.flexibleSpace()]
	final lazy var topRightButtons = [editButtonItem]
	final lazy var viewingModeToolbarButtons = playbackButtons
	
	// MARK: Subclasses Should Not Customize
	
	// Playback
	final private(set) lazy var playbackButtons = [
		previousSongButton, .flexibleSpace(),
		rewindButton, .flexibleSpace(),
//		skipBackwardButton, .flexibleSpace(),
		playPauseButton, .flexibleSpace(),
//		skipForwardButton, .flexibleSpace(),
		nextSongButton,
	]
	final private(set) lazy var previousSongButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			title: LocalizedString.previousTrack,
			image: UIImage(systemName: .SFPreviousTrack),
			primaryAction: UIAction { _ in self.goToPreviousSong() })
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	final private(set) lazy var rewindButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			title: LocalizedString.restart,
			image: UIImage(systemName: .SFRewind),
			primaryAction: UIAction { _ in self.rewind() })
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	final private(set) lazy var skipBackwardButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			title: LocalizedString.skip10SecondsBackwards,
			image: UIImage(systemName: .SFSkipBack10),
			primaryAction: UIAction { _ in self.skipBackward(seconds: 10) })
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	final private(set) lazy var playPauseButton = UIBarButtonItem()
	final private(set) lazy var skipForwardButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			title: LocalizedString.skip10SecondsForward,
			image: UIImage(systemName: .SFSkipForward10),
			primaryAction: UIAction { _ in self.skipForward(seconds: 10) })
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	final private(set) lazy var nextSongButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			title: LocalizedString.nextTrack,
			image: UIImage(systemName: .SFNextTrack),
			primaryAction: UIAction { _ in self.goToNextSong() })
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	
	// Controls
	final private(set) lazy var sortButton = UIBarButtonItem(
		title: LocalizedString.sort,
		menu: makeSortOptionsMenu())
	final private(set) lazy var floatToTopButton = UIBarButtonItem(
		title: LocalizedString.moveToTop,
		image: UIImage(systemName: "arrow.up.to.line.compact"),
		primaryAction: UIAction { _ in self.floatSelectedItemsToTopOfSection() })
	final private(set) lazy var sinkToBottomButton = UIBarButtonItem(
		title: LocalizedString.moveToBottom,
		image: UIImage(systemName: "arrow.down.to.line.compact"),
		primaryAction: UIAction { _ in self.sinkSelectedItemsToBottomOfSection() })
	final private(set) lazy var cancelAndDismissButton = UIBarButtonItem(
		systemItem: .cancel,
		primaryAction: UIAction { _ in self.dismiss(animated: true) })
	
	// State
	final var isMergingChanges = false
	final var needsFreshenLibraryItemsOnAppear = false
	final private var isAnimatingBatchUpdates = 0
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		beginReflectingPlaybackState()
		
		setUp()
	}
	
	final func setUp() {
		beginObservingNotifications()
		setUpUI()
	}
	
	func setUpUI() {
		freshenNavigationItemTitle()
		
		setBarButtons(animated: false)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if needsFreshenLibraryItemsOnAppear {
			needsFreshenLibraryItemsOnAppear = false
			freshenLibraryItems()
		}
	}
	
	// MARK: Teardown
	
	deinit {
		endReflectingPlaybackState()
		
		NotificationCenter.default.removeObserver(self)
	}
	
	// MARK: - Setting Items
	
	final func setViewModelAndMoveRows(
		firstReloading toReload: [IndexPath] = [],
		_ newViewModel: LibraryViewModel,
		thenSelecting toSelect: Set<IndexPath> = [],
		runningBeforeContinuation beforeContinuation: (() -> Void)? = nil
	) async {
		await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
			_setViewModelAndMoveRows(
				firstReloading: toReload,
				newViewModel,
				thenSelecting: toSelect
			) {
				continuation.resume()
			}
			beforeContinuation?()
		}
	}
	
	private func _setViewModelAndMoveRows(
		firstReloading toReload: [IndexPath] = [],
		_ newViewModel: LibraryViewModel,
		thenSelecting toSelect: Set<IndexPath> = [],
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
		
		isAnimatingBatchUpdates += 1
		tableView.performBatchUpdates(
			firstReloading: toReload,
			with: .fade,
			thenMovingSections: sectionBatchUpdates,
			andRows: rowBatchUpdates,
			with: .middle
		) {
			self.isAnimatingBatchUpdates -= 1
			if self.isAnimatingBatchUpdates == 0 { // If we call `performBatchUpdates` multiple times quickly, executions after the first one can beat the first one to the completion closure, because they don’t have to animate anything. Here, we wait for the animations to finish before we run the completion closure (once).
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
	
	// MARK: - Freshening UI
	
	func reflectViewModelIsEmpty() {
		fatalError()
	}
	
	// `LibraryTVC` itself doesn't call this, but its subclasses might want to.
	final func deleteThenExit(sections toDelete: [Int]) {
		tableView.deselectAllRows(animated: true)
		
		isAnimatingBatchUpdates += 1
		tableView.performBatchUpdates {
			tableView.deleteSections(IndexSet(toDelete), with: .middle)
		} completion: { _ in
			self.isAnimatingBatchUpdates -= 1
			if self.isAnimatingBatchUpdates == 0 { // See corresponding comment in `setItemsAndMoveRows`.
				self.dismiss(animated: true) { // If we moved all the `Album`s out of a `Collection`, we need to wait until we’ve completely dismissed the “move albums” sheet before we exit. Otherwise, we’ll fail to exit and get trapped in a blank `AlbumsTVC`.
					self.performSegue(withIdentifier: "Removed All Contents", sender: self)
				}
			}
		}
		
		didChangeRowsOrSelectedRows()
	}
	
	final func freshenNavigationItemTitle() {
		title = viewModel.bigTitle()
	}
	
	func showToolbar() {
		navigationController?.toolbar.isHidden = false
	}
	
	func hideToolbar() {
		navigationController?.toolbar.isHidden = true
	}
	
	private func setBarButtons(animated: Bool) {
		freshenEditingButtons()
		navigationItem.setRightBarButtonItems(topRightButtons, animated: animated)
		
		if isEditing {
			navigationItem.setLeftBarButtonItems(editingModeTopLeftButtons, animated: animated)
			setToolbarItems(editingModeToolbarButtons, animated: animated)
		} else {
			navigationItem.setLeftBarButtonItems(viewingModeTopLeftButtons, animated: animated)
			
			freshenPlaybackButtons()
			setToolbarItems(viewingModeToolbarButtons, animated: animated)
		}
	}
	
	final func didChangeRowsOrSelectedRows() {
		freshenEditingButtons()
	}
	
	// Overrides should call super (this implementation).
	func freshenEditingButtons() {
		// There can momentarily be 0 library items if we’re freshening to reflect changes in the Music library.
		
		editButtonItem.isEnabled = allowsEdit()
		
		sortButton.isEnabled = allowsSort()
		floatToTopButton.isEnabled = allowsFloatAndSink()
		sinkToBottomButton.isEnabled = allowsFloatAndSink()
	}
	
	private func allowsEdit() -> Bool {
		return !viewModel.isEmpty()
	}
	
	// Overrides should call super (this implementation).
	final override func setEditing(_ editing: Bool, animated: Bool) {
		if !editing {
			let newViewModel = viewModel.updatedWithFreshenedData() // Deletes empty groups if we reordered all the items out of them.
			_setViewModelAndMoveRows(newViewModel) // As of iOS 15.4 developer beta 1, by default, `UITableViewController` deselects rows during `setEditing` without animating them.
			// As of iOS 15.4 developer beta 1, to animate deselecting rows, you must do so before `super.setEditing`, not after.
			
			newViewModel.context.tryToSave()
		}
		
		super.setEditing(editing, animated: animated)
		
		setBarButtons(animated: animated)
		
		tableView.performBatchUpdates(nil) // Makes the cells resize themselves (expand if text has wrapped around to new lines; shrink if text has unwrapped into fewer lines). Otherwise, they’ll stay the same size until they reload some other time, like after you edit them or scroll them offscreen and back onscreen.
		// During a WWDC 2021 lab, a UIKit engineer told me that this is the best practice for doing that.
		// As of iOS 15.4 developer beta 1, you must do this after `super.setEditing`, not before.
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
