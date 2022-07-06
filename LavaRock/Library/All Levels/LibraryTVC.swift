//
//  LibraryTVC.swift
//  LavaRock
//
//  Created by h on 2020-04-15.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import MediaPlayer
import SwiftUI

class LibraryTVC: UITableViewController {
	// MARK: - Properties
	
	// MARK: Subclasses Should Customize
	
	// Data
	final lazy var viewModel: LibraryViewModel = CollectionsViewModel(
		context: Database.viewContext,
		prerowsInEachSection: [])
	
	// Controls
	final var editingModeToolbarButtons: [UIBarButtonItem] = []
	final var sortOptionsGrouped: [[LibrarySortOption]] = []
	
	// MARK: Subclasses Can Optionally Customize
	
	// Controls
	final var viewingModeTopLeftButtons: [UIBarButtonItem] = []
	final lazy var editingModeTopLeftButtons: [UIBarButtonItem] = [
		.flexibleSpace(),
	]
	final lazy var viewingModeTopRightButtons: [UIBarButtonItem] = [
		// Right to left
		editButtonItem,
	]
	final lazy var editingModeTopRightButtons: [UIBarButtonItem] = [
		editButtonItem,
	]
	final lazy var viewingModeToolbarButtons = (navigationController as? LibraryNC)?.transportBar.buttons
	
	// MARK: Subclasses Should Not Customize
	
	final var player: MPMusicPlayerController? { TapeDeck.shared.player }
	
	// Controls
	private(set) final var sortButton = UIBarButtonItem(
		title: LocalizedString.sort)
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
		
		TapeDeck.shared.addReflector(weakly: self)
		
		NotificationCenter.default.addObserverOnce(
			self,
			selector: #selector(mergedChanges),
			name: .mergedChanges,
			object: nil)
		
		freshenNavigationItemTitle()
		setUpBarButtons()
	}
	@objc private func mergedChanges() {
		reflectDatabase()
	}
	
	final func freshenNavigationItemTitle() {
		title = viewModel.bigTitle()
	}
	
	// Overrides should call super (this implementation).
	func setUpBarButtons() {
		setBarButtons(animated: false)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if needsFreshenLibraryItemsOnViewDidAppear {
			needsFreshenLibraryItemsOnViewDidAppear = false
			freshenLibraryItems()
		}
	}
	
	// MARK: - Library Items
	
	final func reflectDatabase() {
		// Do this even if the view isn’t visible.
		reflectPlayhead_library()
		
		if view.window == nil {
			needsFreshenLibraryItemsOnViewDidAppear = true
		} else {
			freshenLibraryItems()
		}
	}
	
	func shouldDismissAllViewControllersBeforeFreshenLibraryItems() -> Bool {
		if
			(presentedViewController as? UINavigationController)?.viewControllers.first is ConsoleVC
				|| presentedViewController is UIHostingController<ConsoleView>
		{
			return false
		}
		return true
	}
	
	func freshenLibraryItems() {
		isMergingChanges = false
		
		Task {
			/*
			 When we need to freshen, you might be in the middle of a content-dependent task. For simplicity, cancel such tasks.
			 - Sort options (`LibraryTVC`)
			 - “Rename Collection” dialog (`CollectionsTVC`)
			 - “Combine Collections” dialog (`CollectionsTVC`)
			 - “Organize or move albums?” menu (`AlbumsTVC`)
			 - “Organize albums” sheet (`CollectionsTVC` and `AlbumsTVC` when in “organize albums” sheet)
			 - “Move albums” sheet (`CollectionsTVC` and `AlbumsTVC` when in “move albums” sheet)
			 - “New Collection” dialog (`CollectionsTVC` when in “move albums” sheet)
			 - Song actions (`SongsTVC`)
			 - (Editing mode is a special state, but freshening in editing mode is fine (with no other “breath-holding modes” presented).)
			 */
			if shouldDismissAllViewControllersBeforeFreshenLibraryItems() {
				await view.window?.rootViewController?.dismiss__async(animated: true)
			}
			
			let newViewModel = viewModel.updatedWithFreshenedData()
			guard await setViewModelAndMoveRowsAndShouldContinue(newViewModel) else { return }
			
			freshenNavigationItemTitle()
			// Update the data within each row (and header), which might be outdated.
			// Doing it without an animation looks fine, because we animated the deletes, inserts, and moves earlier; here, we just change the contents of the rows after they stop moving.
			tableView.reconfigureRows(at: tableView.indexPathsForVisibleRowsNonNil)
		}
	}
	
	func reflectViewModelIsEmpty() {
		fatalError()
	}
	
	// Returns after completing the animations for moving rows, with a value of whether it’s safe for the caller to continue running code after those animations. If the return value is `false`, there might be another execution of animating rows still in progress, or this view controller might be about to dismiss itself, and callers could disrupt those animations by running code at those times.
	final func setViewModelAndMoveRowsAndShouldContinue(
		firstReloading toReload: [IndexPath] = [],
		_ newViewModel: LibraryViewModel,
		thenSelecting toSelect: Set<IndexPath> = [],
		runningBeforeContinuation beforeContinuation: (() -> Void)? = nil
	) async -> Bool {
		await withCheckedContinuation { continuation in
			__setViewModelAndMoveRows(
				firstReloading: toReload,
				newViewModel,
				thenSelecting: toSelect
			) { shouldContinue in
				continuation.resume(returning: shouldContinue)
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
		// “'async' call in a function that does not support concurrency”
		tableView.update__completion(
			firstReloading: toReload,
			with: .fade,
			thenMovingSections: sectionBatchUpdates,
			andRows: rowBatchUpdates,
			with: .middle
		) {
			self.isAnimatingBatchUpdates -= 1
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
	
	// `LibraryTVC` itself doesn’t call this, but its subclasses might want to.
	final func deleteThenExit(sections toDelete: [SectionIndex]) {
		tableView.deselectAllRows(animated: true)
		
		isAnimatingBatchUpdates += 1
		tableView.performBatchUpdates {
			tableView.deleteSections(
				IndexSet(toDelete.map { $0.value }),
				with: .middle)
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
	
	// MARK: - Player
	
	final func reflectPlayhead_library() {
		tableView.indexPathsForVisibleRowsNonNil.forEach { visibleIndexPath in
			guard let cell = tableView.cellForRow(at: visibleIndexPath) as? PlayheadReflectable else { return }
			cell.reflectPlayhead(
				containsPlayhead: {
					guard let libraryItem = viewModel.itemOptional(at: visibleIndexPath) as? LibraryItem else {
						return false
					}
					return libraryItem.containsPlayhead()
				}(),
				bodyOfAccessibilityLabel: cell.bodyOfAccessibilityLabel)
		}
	}
	
	// MARK: - Freshening UI
	
	private func setBarButtons(animated: Bool) {
		let editing = isEditing
		
		freshenEditingButtons() // Do this always, not just when `isEditing`, because on a clean install, we need to disable the “Edit” button.
		
		navigationItem.setLeftBarButtonItems(
			editing
			? editingModeTopLeftButtons
			: viewingModeTopLeftButtons,
			animated: animated)
		navigationItem.setRightBarButtonItems(
			editing
			? editingModeTopRightButtons
			: viewingModeTopRightButtons,
			animated: animated)
		
		setToolbarItems(
			editing
			? editingModeToolbarButtons
			: viewingModeToolbarButtons,
			animated: animated)
	}
	
	// For clarity, call this rather than `freshenEditingButtons` directly, whenever possible.
	final func didChangeRowsOrSelectedRows() {
		freshenEditingButtons()
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
		
		setBarButtons(animated: animated)
		
		tableView.performBatchUpdates(nil) // Makes the cells resize themselves (expand if text has wrapped around to new lines; shrink if text has unwrapped into fewer lines). Otherwise, they’ll stay the same size until they reload some other time, like after you edit them or scroll them offscreen and back onscreen.
		// During a WWDC 2021 lab, a UIKit engineer told me that this is the best practice for doing that.
		// As of iOS 15.4 developer beta 1, you must do this after `super.setEditing`, not before.
	}
	
	// Overrides should call super (this implementation).
	func freshenEditingButtons() {
		// There can momentarily be 0 library items if we’re freshening to reflect changes in the Music library.
		
		editButtonItem.isEnabled = !viewModel.isEmpty()
		
		sortButton.isEnabled = allowsSort()
		sortButton.menu = makeSortOptionsMenu()
		floatToTopButton.isEnabled = allowsFloatAndSink()
		sinkToBottomButton.isEnabled = allowsFloatAndSink()
	}
	
	// You should only be allowed to sort items that are contiguous and within the same `LibraryGroup`.
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
