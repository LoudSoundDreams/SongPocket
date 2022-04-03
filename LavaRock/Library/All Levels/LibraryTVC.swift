//
//  LibraryTVC.swift
//  LavaRock
//
//  Created by h on 2020-04-15.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import MediaPlayer

class LibraryTVC: UITableViewController {
	enum SortOption: CaseIterable {
		// For `Collection`s only
		case title
		
		// For `Album`s only
		case newestFirst
		case oldestFirst
		
		// For `Song`s only
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
	final lazy var viewingModeToolbarButtons = playbackToolbarButtons
	
	// MARK: Subclasses Should Not Customize
	
	// `PlaybackToolbarManaging`
	private(set) lazy var previousSongButton = makePreviousSongButton()
	private(set) lazy var rewindButton = makeRewindButton()
	private(set) lazy var skipBackwardButton = makeSkipBackwardButton()
	private(set) lazy var playPauseButton = UIBarButtonItem()
	private(set) lazy var skipForwardButton = makeSkipForwardButton()
	private(set) lazy var nextSongButton = makeNextSongButton()
	
	// Controls
	private(set) final lazy var sortButton = UIBarButtonItem(
		title: LocalizedString.sort,
		menu: makeSortOptionsMenu())
	private(set) final lazy var floatToTopButton = UIBarButtonItem(
		title: LocalizedString.moveToTop,
		image: UIImage(systemName: "arrow.up.to.line.compact"),
		primaryAction: UIAction { [weak self] _ in self?.floatSelectedItemsToTopOfSection() })
	private(set) final lazy var sinkToBottomButton = UIBarButtonItem(
		title: LocalizedString.moveToBottom,
		image: UIImage(systemName: "arrow.down.to.line.compact"),
		primaryAction: UIAction { [weak self] _ in self?.sinkSelectedItemsToBottomOfSection() })
	private(set) final lazy var cancelAndDismissButton = UIBarButtonItem(
		systemItem: .cancel,
		primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) })
	
	// State
	final var isMergingChanges = false
	final var needsFreshenLibraryItemsOnViewDidAppear = false
	private var isAnimatingBatchUpdates = 0
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		beginReflectingPlaybackState()
		
		NotificationCenter.default.addObserverOnce(
			self,
			selector: #selector(didMergeChanges),
			name: .LRDidMergeChanges,
			object: MusicLibraryWatcher.shared)
		NotificationCenter.default.addObserverOnce(
			self,
			selector: #selector(songQueueDidChange),
			name: .LRSongQueueDidChange,
			object: nil)
		
		beginObservingNowPlayingItemDidChange()
		
		freshenNavigationItemTitle()
		setUpBarButtons()
	}
	@objc private func didMergeChanges() { reflectDatabase() }
	@objc private func songQueueDidChange() {
		freshenPlaybackToolbar()
	}
	
	final func beginObservingNowPlayingItemDidChange() {
		if MPMediaLibrary.authorizationStatus() == .authorized {
			NotificationCenter.default.addObserverOnce(
				self,
				selector: #selector(nowPlayingItemDidChange),
				name: .MPMusicPlayerControllerNowPlayingItemDidChange,
				object: player)
		}
	}
	@objc private func nowPlayingItemDidChange() { freshenNowPlayingIndicatorsAndPlaybackToolbar() }
	
	final func freshenNavigationItemTitle() {
		title = viewModel.bigTitle()
	}
	
	// Overrides should call super (this implementation).
	func setUpBarButtons() {
		setBarButtons(animated: false)
		if Enabling.playerScreen {
			setToolbarItems(editingModeToolbarButtons, animated: false)
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if needsFreshenLibraryItemsOnViewDidAppear {
			needsFreshenLibraryItemsOnViewDidAppear = false
			freshenLibraryItems()
		}
	}
	
	// MARK: - Setting Items
	
	// Returns after completing the animations for moving rows, with a value of whether it’s safe for the caller to continue running code after those animations. If the return value is `false`, there might be another execution of animating rows still in progress, or this view controller might be about to dismiss itself, and callers could disrupt those animations by running code at those times.
	final func setViewModelAndMoveRowsAndShouldContinue(
		firstReloading toReload: [IndexPath] = [],
		_ newViewModel: LibraryViewModel,
		thenSelecting toSelect: Set<IndexPath> = [],
		runningBeforeContinuation beforeContinuation: (() -> Void)? = nil
	) async -> Bool {
		return await withCheckedContinuation { continuation in
			__setViewModelAndMoveRows(
				firstReloading: toReload,
				newViewModel,
				thenSelecting: toSelect
			) { shouldContinue in
//				Task { await MainActor.run { // This might be necessary. https://www.swiftbysundell.com/articles/the-main-actor-attribute/
				continuation.resume(returning: shouldContinue)
//				}}
			}
			beforeContinuation?()
		}
	}
	
	private func __setViewModelAndMoveRows(
		firstReloading toReload: [IndexPath] = [],
		_ newViewModel: LibraryViewModel,
		thenSelecting toSelect: Set<IndexPath> = [],
		completionIfShouldRun: @escaping (Bool) -> Void // We used to use `completion: @escaping () -> Void` here and just not run it every time, but that leaked `CheckedContinuation` if you wrapped this method in `withCheckedContinuation` and resumed the continuation during that handler. Hence, this method always runs the completion handler, and callers should pass in completion handlers that return immediately if the parameter is `false`.
	) {
		let oldViewModel = viewModel
		
		viewModel = newViewModel
		
		guard !newViewModel.isEmpty() else {
			completionIfShouldRun(false)
			reflectViewModelIsEmpty()
			return
		}
		
		let oldSections = oldViewModel.sectionStructures()
		let newSections = newViewModel.sectionStructures()
		let sectionBatchUpdates = oldSections.differenceInferringMoves(toMatch: newSections) {
			oldSection, newSection in
			oldSection.identifier == newSection.identifier
		}.batchUpdates()
		
		// Determine the batch updates for the rows within each section.
		let oldSectionIdentifiersAndIndices = zip(
			oldSections.map { $0.identifier },
			oldSections.indices)
		let oldSectionIndicesByIdentifier = Dictionary(uniqueKeysWithValues: oldSectionIdentifiersAndIndices)
		var rowBatchUpdates: [BatchUpdates<IndexPath>] = []
		newSections.enumerated().forEach { (newSectionIndex, newSection) in
			let sectionIdentifier = newSection.identifier
			// We never delete, insert, or move rows into or out of deleted or inserted sections, because when we delete or insert sections, we also delete or insert all the rows within them.
			// We also never move rows between sections with different identifiers, because we only compare sections with equivalent identifiers.
			guard let oldSectionIndex = oldSectionIndicesByIdentifier[sectionIdentifier] else { return }
			
			let rowBatchUpdatesInSection = Self.batchUpdatesOfRows(
				oldSection: oldSectionIndex,
				oldIdentifiers: oldSections[oldSectionIndex].rowIdentifiers,
				newSection: newSectionIndex,
				newIdentifiers: newSection.rowIdentifiers)
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
			self.isAnimatingBatchUpdates -= 1 // ARC2DO
			if self.isAnimatingBatchUpdates == 0 { // If we call `performBatchUpdates` multiple times quickly, executions after the first one can beat the first one to the completion closure, because they don’t have to animate anything. Here, we wait for the animations to finish before we run the completion closure (once).
				completionIfShouldRun(true)
			} else {
				completionIfShouldRun(false)
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
	
	private static func batchUpdatesOfRows<Identifier: Hashable>(
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
	
	func reflectViewModelIsEmpty() {
		fatalError()
	}
	
	// `LibraryTVC` itself doesn’t call this, but its subclasses might want to.
	final func deleteThenExit(sections toDelete: [Int]) {
		tableView.deselectAllRows(animated: true)
		
		isAnimatingBatchUpdates += 1
		tableView.performBatchUpdates {
			tableView.deleteSections(IndexSet(toDelete), with: .middle)
		} completion: { _ in
			self.isAnimatingBatchUpdates -= 1 // ARC2DO
			if self.isAnimatingBatchUpdates == 0 { // See corresponding comment in `setItemsAndMoveRows`.
				self.dismiss(animated: true) { // If we moved all the `Album`s out of a `Collection`, we need to wait until we’ve completely dismissed the “move albums” sheet before we exit. Otherwise, we’ll fail to exit and get trapped in a blank `AlbumsTVC`.
					self.performSegue(withIdentifier: "Removed All Contents", sender: self)
				}
			}
		}
		
		didChangeRowsOrSelectedRows()
	}
	
	// MARK: - Freshening UI
	
	private func setBarButtons(animated: Bool) {
		freshenEditingButtons()
		
		if isEditing {
			navigationItem.setLeftBarButtonItems(editingModeTopLeftButtons, animated: animated)
			setToolbarItems(editingModeToolbarButtons, animated: animated)
		} else {
			navigationItem.setLeftBarButtonItems(viewingModeTopLeftButtons, animated: animated)
			if Enabling.playerScreen {
			} else {
				freshenPlaybackToolbar()
				setToolbarItems(viewingModeToolbarButtons, animated: animated)
			}
		}
	}
	
	// For clarity, call this rather than `freshenEditingButtons` directly, whenever possible.
	final func didChangeRowsOrSelectedRows() {
		freshenEditingButtons()
	}
	
	// Overrides should call super (this implementation).
	func freshenEditingButtons() {
		// There can momentarily be 0 library items if we’re freshening to reflect changes in the Music library.
		
		editButtonItem.isEnabled = !viewModel.isEmpty()
		
		sortButton.isEnabled = allowsSort()
		floatToTopButton.isEnabled = allowsFloatAndSink()
		sinkToBottomButton.isEnabled = allowsFloatAndSink()
	}
	
	// Overrides should call super (this implementation).
	final override func setEditing(_ editing: Bool, animated: Bool) {
		if !editing {
			let newViewModel = viewModel.updatedWithFreshenedData() // Deletes empty groups if we reordered all the items out of them.
			__setViewModelAndMoveRows(newViewModel, completionIfShouldRun: { shouldRun in }) // As of iOS 15.4 developer beta 1, by default, `UITableViewController` deselects rows during `setEditing` without animating them.
			// As of iOS 15.4 developer beta 1, to animate deselecting rows, you must do so before `super.setEditing`, not after.
			
			newViewModel.context.tryToSave()
		}
		
		super.setEditing(editing, animated: animated)
		
		if Enabling.playerScreen {
			navigationController?.setToolbarHidden(!editing, animated: true)
		} else {
			setBarButtons(animated: animated)
		}
		
		tableView.performBatchUpdates(nil) // Makes the cells resize themselves (expand if text has wrapped around to new lines; shrink if text has unwrapped into fewer lines). Otherwise, they’ll stay the same size until they reload some other time, like after you edit them or scroll them offscreen and back onscreen.
		// During a WWDC 2021 lab, a UIKit engineer told me that this is the best practice for doing that.
		// As of iOS 15.4 developer beta 1, you must do this after `super.setEditing`, not before.
	}
	
	// You should only be allowed to sort contiguous items within the same `GroupOfLibraryItems`.
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
