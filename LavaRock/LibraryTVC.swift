//
//  LibraryTVC.swift
//  LavaRock
//
//  Created by h on 2020-04-15.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit

extension UITableViewCell {
	final func backgroundColors_configureForLibraryItem() {
		backgroundColor = .clear
		selectedBackgroundView = {
			let result = UIView()
			result.backgroundColor = .tintColor.withAlphaComponent(.oneHalf)
			return result
		}()
	}
}

class LibraryTVC: UITableViewController {
	final lazy var viewModel: LibraryViewModel = CollectionsViewModel(context: Database.viewContext)
	
	final var editingButtons: [UIBarButtonItem] = []
	private(set) final lazy var floatButton = UIBarButtonItem(
		title: LRString.moveToTop,
		image: UIImage(systemName: "arrow.up.to.line"),
		primaryAction: UIAction { [weak self] _ in self?.floatSelected() })
	private func floatSelected() {
		let unorderedRows = tableView.selectedIndexPaths.map { $0.row }
		let unorderedIndices = unorderedRows.map {
			viewModel.itemIndex(forRow: $0)
		}
		
		var newItems = viewModel.libraryGroup().items
		newItems.move(fromOffsets: IndexSet(unorderedIndices), toOffset: 0)
		
		var newViewModel = viewModel
		newViewModel.groups[0].items = newItems
		Task {
			let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel)
		}
	}
	private(set) final lazy var sinkButton = UIBarButtonItem(
		title: LRString.moveToBottom,
		image: UIImage(systemName: "arrow.down.to.line"),
		primaryAction: UIAction { [weak self] _ in self?.sinkSelected() })
	private func sinkSelected() {
		let unorderedRows = tableView.selectedIndexPaths.map { $0.row }
		let unorderedIndices = unorderedRows.map {
			viewModel.itemIndex(forRow: $0)
		}
		
		var newItems = viewModel.libraryGroup().items
		newItems.move(fromOffsets: IndexSet(unorderedIndices), toOffset: newItems.count)
		
		var newViewModel = viewModel
		newViewModel.groups[0].items = newItems
		Task {
			let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel)
		}
	}
	
	final var isMergingChanges = false
	final var needsFreshenLibraryItemsOnViewDidAppear = false
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		NotificationCenter.default.addObserverOnce(self, selector: #selector(reflectDatabase), name: .LRMergedChanges, object: nil)
		
		view.backgroundColor = UIColor(LRColor.grey_oneEighth)
		
		if let navBar = navigationController?.navigationBar {
			navBar.scrollEdgeAppearance = navBar.standardAppearance
		}
		
		setBarButtons(animated: false)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if needsFreshenLibraryItemsOnViewDidAppear {
			needsFreshenLibraryItemsOnViewDidAppear = false
			freshenLibraryItems()
		}
	}
	
	// MARK: - Library items
	
	@objc func reflectDatabase() {
		if view.window == nil {
			needsFreshenLibraryItemsOnViewDidAppear = true
		} else {
			freshenLibraryItems()
		}
	}
	
	func freshenLibraryItems() {
		isMergingChanges = false
		Task {
			/*
			 The user might currently be in the middle of a content-dependent task, which freshening would affect the consequences of.
			 • “Sort” menu (`LibraryTVC`)
			 • “Rename” dialog (`CollectionsTVC`)
			 • “Move albums” sheet (`CollectionsTVC` and `AlbumsTVC` when in “move albums” sheet)
			 • Song actions, including overflow menu (`SongsTVC`)
			 */
			await view.window?.rootViewController?.dismiss__async(animated: true)
			
			let newViewModel = viewModel.updatedWithFreshenedData()
			guard await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel) else {
				// The return value was false, meaning either (1) table view animations are already in progress from an earlier execution of this method, so we shouldn’t run the code after the `await` call this time (that earlier execution will), or (2) we applied an empty view model, so we don’t need to update any row contents.
				return
			}
			
			// Update the data within each row, which might be outdated.
			// Doing it without an animation looks fine, because we animated the deletes, inserts, and moves earlier; here, we just change the contents of the rows after they stop moving.
			tableView.reconfigureRows(at: tableView.allIndexPaths())
		}
	}
	
	func reflectViewModelIsEmpty() {
		fatalError()
	}
	
	// Returns after completing the animations for moving rows, with a value of whether it’s safe for the caller to continue running code after those animations. If the return value is `false`, there might be another execution of animating rows still in progress, or this view controller might be about to dismiss itself, and callers could disrupt those animations by running code at those times.
	final func setViewModelAndMoveAndDeselectRowsAndShouldContinue(
		_ newViewModel: LibraryViewModel
	) async -> Bool {
		await withCheckedContinuation { continuation in
			_setViewModelAndMoveAndDeselectRows(
				newViewModel
			) { shouldContinue in
				continuation.resume(returning: shouldContinue)
			}
			// If necessary, include code here to run before the continuation.
		}
	}
	private var isAnimatingBatchUpdates = 0
	private func _setViewModelAndMoveAndDeselectRows(
		_ newViewModel: LibraryViewModel,
		completionIfShouldRun: @escaping (Bool) -> Void // We used to sometimes not run this completion handler, but if you wrapped this method in `withCheckedContinuation` and resumed the continuation during that handler, that leaked `CheckedContinuation`. Hence, this method always runs the completion handler, and callers should pass a completion handler that returns immediately if the parameter is `false`.
	) {
		let oldViewModel = viewModel
		
		viewModel = newViewModel // Can be empty
		
		guard !newViewModel.isEmpty() else {
			completionIfShouldRun(false)
			reflectViewModelIsEmpty()
			return
		}
		
		let batchUpdates = Self.batchUpdatesFromIdentifiers(
			old: oldViewModel.rowIdentifiers(),
			new: newViewModel.rowIdentifiers())
		
		isAnimatingBatchUpdates += 1
		tableView.applyBatchUpdates(batchUpdates) {
			// Completion handler
			self.isAnimatingBatchUpdates -= 1
			if self.isAnimatingBatchUpdates == 0 { // If we call `performBatchUpdates` multiple times quickly, executions after the first one can beat the first one to the completion closure, because they don’t have to animate any rows. Here, we wait for the animations to finish before we run the completion closure (once).
				completionIfShouldRun(true)
			} else {
				completionIfShouldRun(false)
			}
		}
		
		tableView.deselectAllRows(animated: true)
		
		freshenEditingButtons()
	}
	private static func batchUpdatesFromIdentifiers
	<Identifier: Hashable>(old: [Identifier], new: [Identifier])
	-> BatchUpdates<IndexPath> {
		let updates = old.differenceInferringMoves(toMatch: new, by: ==)
			.batchUpdates()
		
		let section = 0
		let toDelete = updates.toDelete.map { IndexPath(row: $0, section: section) }
		let toInsert = updates.toInsert.map { IndexPath(row: $0, section: section) }
		let toMove = updates.toMove.map { (oldRow, newRow) in
			(IndexPath(row: oldRow, section: section),
			 IndexPath(row: newRow, section: section))
		}
		return BatchUpdates(toDelete: toDelete, toInsert: toInsert, toMove: toMove)
	}
	// `LibraryTVC` itself doesn’t call this, but its subclasses might want to.
	final func deleteThenExit(sectionsToDelete: [Int]) {
		tableView.deselectAllRows(animated: true)
		
		isAnimatingBatchUpdates += 1
		tableView.performBatchUpdates {
			tableView.deleteSections(
				IndexSet(sectionsToDelete),
				with: .middle)
		} completion: { _ in
			self.isAnimatingBatchUpdates -= 1
			if self.isAnimatingBatchUpdates == 0 { // See corresponding comment in `setViewModelAndMoveAndDeselectRowsAndShouldContinue`.
				self.dismiss(animated: true) { // If we moved all the albums out of a collection, we need to wait until we’ve completely dismissed the “move albums” sheet before we exit. Otherwise, we’ll fail to exit and get trapped in a blank `AlbumsTVC`.
					self.performSegue(withIdentifier: "Removed All Contents", sender: self)
				}
			}
		}
		
		freshenEditingButtons()
	}
	
	// MARK: - Navigation
	
	final override func shouldPerformSegue(
		withIdentifier identifier: String, sender: Any?
	) -> Bool {
		return !isEditing
	}
	
	// MARK: - Freshening UI
	
	private func setBarButtons(animated: Bool) {
		let editing = isEditing
		
		freshenEditingButtons() // Do this always, not just when `isEditing`, because on a clean install, we need to disable the “Edit” button.
		
		navigationItem.setLeftBarButtonItems(
			(
				editing
				? [.flexibleSpace()] // Removes “Back” button
				: []
			),
			animated: animated)
		
		setToolbarItems(
			(
				editing
				? editingButtons
				: [editButtonItem] + MainToolbar.shared.barButtonItems
			),
			animated: animated)
	}
	
	// Overrides should call super (this implementation).
	override func setEditing(_ editing: Bool, animated: Bool) {
		if !editing {
			// As of iOS 17.3 developer beta 1, by default, `UITableViewController` deselects rows during `setEditing`, but without animating them.
			// As of iOS 17.3 developer beta 1, to animate deselecting rows, you must do so before `super.setEditing`, not after.
			tableView.deselectAllRows(animated: true)
			
			viewModel.context.tryToSave()
		}
		
		super.setEditing(editing, animated: animated)
		
		setBarButtons(animated: animated)
		
		// As of iOS 16.2 developer beta 1, we still have to do this. Also, `tableView.selfSizingInvalidation` must not be `.enabledIncludingConstraints`, or the animation breaks.
		tableView.performBatchUpdates(nil) // Makes the cells resize themselves (expand if text has wrapped around to new lines; shrink if text has unwrapped into fewer lines). Otherwise, they’ll stay the same size until they reload some other time, like after you edit them or scroll them offscreen and back onscreen.
		// During a WWDC 2021 lab, a UIKit engineer told me that this is the best practice for doing that.
		// As of iOS 15.4 developer beta 1, you must do this after `super.setEditing`, not before.
	}
	
	// Overrides should call super (this implementation).
	func freshenEditingButtons() {
		// There can momentarily be 0 library items if we’re freshening to reflect changes in the Music library.
		
		editButtonItem.isEnabled = !viewModel.isEmpty()
		editButtonItem.image = (
			isEditing
			? UIImage(systemName: "checkmark.circle.fill")
			: UIImage(systemName: "checkmark.circle")
		)
		
		let allowsFloatAndSink: Bool = {
			guard !viewModel.isEmpty() else {
				return false
			}
			return !tableView.selectedIndexPaths.isEmpty
		}()
		floatButton.isEnabled = allowsFloatAndSink
		sinkButton.isEnabled = allowsFloatAndSink
	}
	final func allowsArrange() -> Bool {
		guard !viewModel.isEmpty() else {
			return false
		}
		let selectedIndexPaths = tableView.selectedIndexPaths
		if selectedIndexPaths.isEmpty {
			return true
		} else {
			var selectedRows = selectedIndexPaths.map { $0.row }
			selectedRows.sort()
			return selectedRows.isConsecutive()
		}
	}
	final func unsortedRowsToArrange() -> [Int] {
		var result: [Int] = tableView.selectedIndexPaths.map { $0.row }
		if result.isEmpty {
			result = viewModel.rowsForAllItems()
		}
		return result
	}
	final func arrangeSelectedOrAll(by command: ArrangeCommand) {
		let subjectedRows = unsortedRowsToArrange().sorted()
		let subjectedIndices = subjectedRows.map { viewModel.itemIndex(forRow: $0) }
		let allItems = viewModel.libraryGroup().items
		
		var newViewModel = viewModel
		let newItems = command.apply(
			onOrderedIndices: subjectedIndices,
			in: allItems)
		newViewModel.groups[0].items = newItems
		Task {
			let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel)
		}
	}
	
	// MARK: - Table view
	
	final override func tableView(
		_ tableView: UITableView, canEditRowAt indexPath: IndexPath
	) -> Bool {
		return viewModel.pointsToSomeItem(row: indexPath.row)
	}
	
	final override func tableView(
		_ tableView: UITableView,
		targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
		toProposedIndexPath proposedDestinationIndexPath: IndexPath
	) -> IndexPath {
		if viewModel.pointsToSomeItem(row: proposedDestinationIndexPath.row) {
			return proposedDestinationIndexPath
		}
		
		// Reordering upward
		if proposedDestinationIndexPath < sourceIndexPath {
			return IndexPath(
				row: viewModel.row(forItemIndex: 0),
				section: proposedDestinationIndexPath.section)
		}
		
		// Reordering downward
		return proposedDestinationIndexPath
	}
	
	final override func tableView(
		_ tableView: UITableView,
		moveRowAt fromIndexPath: IndexPath,
		to: IndexPath
	) {
		let fromIndex = viewModel.itemIndex(forRow: fromIndexPath.row)
		let toIndex = viewModel.itemIndex(forRow: to.row)
		
		var newItems = viewModel.libraryGroup().items
		let itemBeingMoved = newItems.remove(at: fromIndex)
		newItems.insert(itemBeingMoved, at: toIndex)
		viewModel.groups[0].items = newItems
		
		freshenEditingButtons() // If you made selected rows non-contiguous, that should disable the “Sort” button. If you made all the selected rows contiguous, that should enable the “Sort” button.
	}
	
	final override func tableView(
		_ tableView: UITableView, willSelectRowAt indexPath: IndexPath
	) -> IndexPath? {
		return viewModel.pointsToSomeItem(row: indexPath.row) ? indexPath : nil
	}
	
	// Overrides should call super (this implementation) if `viewModel.pointsToSomeItem(indexPath)`.
	override func tableView(
		_ tableView: UITableView, didSelectRowAt indexPath: IndexPath
	) {
		if isEditing {
			if let cell = tableView.cellForRow(at: indexPath) {
				cell.accessibilityTraits.formUnion(.selected)
			}
			freshenEditingButtons()
		}
	}
	
	final override func tableView(
		_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath
	) {
		if let cell = tableView.cellForRow(at: indexPath) {
			cell.accessibilityTraits.subtract(.selected)
		}
		freshenEditingButtons()
	}
}
