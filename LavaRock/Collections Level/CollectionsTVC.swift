//
//  CollectionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-05-04.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import CoreData
import MediaPlayer

enum CollectionsContentState {
	case allowAccess
	case loading
	case blank
	case noCollections
	case oneOrMoreCollections
}

final class CollectionsTVC:
	LibraryTVC,
	AlbumMover
{
	
	// MARK: - Properties
	
	// "Constants"
	lazy var renameFocusedCollectionAction = UIAccessibilityCustomAction(
		name: LocalizedString.rename,
		actionHandler: renameFocusedCollectionHandler)
	private func renameFocusedCollectionHandler(
		_ sender: UIAccessibilityCustomAction
	) -> Bool {
		let indexPathsOfAllCollections = viewModel.indexPathsForAllItems()
		let focusedIndexPath = indexPathsOfAllCollections.first {
			let cell = tableView.cellForRow(at: $0)
			return cell?.accessibilityElementIsFocused() ?? false
		}
		
		if let focusedIndexPath = focusedIndexPath {
			presentDialogToRenameCollection(at: focusedIndexPath)
			return true
		} else {
			return false
		}
	}
	@IBOutlet private var optionsButton: UIBarButtonItem!
	private lazy var combineButton: UIBarButtonItem = {
		let action = UIAction { _ in self.previewCombineSelectedCollectionsAndPresentDialog() }
		return UIBarButtonItem(
			title: LocalizedString.combine,
			primaryAction: action)
	}()
	private lazy var makeNewCollectionButton: UIBarButtonItem = {
		let action = UIAction { _ in self.previewMakeNewCollectionAndPresentDialog() }
		return UIBarButtonItem(
			systemItem: .add,
			primaryAction: action)
	}()
	
	var isAboutToSetItemsAndRefresh = false
	var groupOfCollectionsBeforeCombining: GroupOfLibraryItems?
	
	// MARK: "Moving Albums" Mode
	
	var albumMoverClipboard: AlbumMoverClipboard?
	var didMoveAlbums = false
	
	// MARK: - Content State
	
	final func contentState() -> CollectionsContentState {
		if MPMediaLibrary.authorizationStatus() != .authorized {
			return .allowAccess
		}
		if isAboutToSetItemsAndRefresh { // You must check this before checking isImportingChanges.
			return .blank
		}
		if isImportingChanges {
			if viewModel.isEmpty() {
				return .loading
			} else {
				return .oneOrMoreCollections
			}
		} else {
			if viewModel.isEmpty() {
				return .noCollections
			} else {
				return .oneOrMoreCollections
			}
		}
	}
	
	final func prepareToRefreshLibraryItems() {
		if contentState() == .loading || contentState() == .noCollections {
			isAboutToSetItemsAndRefresh = true // contentState() is now .blank
			refreshToReflectContentState()
			isAboutToSetItemsAndRefresh = false // WARNING: contentState() is now .loading or .noCollections, but the UI doesn't reflect that.
		}
	}
	
	final override func refreshToReflectNoItems() {
		// isImportingChanges is now false
		if contentState() == .noCollections {
			refreshToReflectContentState()
		}
	}
	
	private func refreshToReflectContentState(
		completion: (() -> Void)? = nil
	) {
		let toDelete: [IndexPath]
		let toInsert: [IndexPath]
		let toReload: [IndexPath]
		let animationForReload: UITableView.RowAnimation
		
//		let inAllSection = tableView.indexPathsForRows(
//			inSection: CollectionsSection.all.rawValue,
//			firstRow: 0)
//		let indexOfCollectionsSection = CollectionsSection.collections.rawValue
		let indexOfCollectionsSection = 0
		let oldInCollectionsSection = tableView.indexPathsForRows(
			inSection: indexOfCollectionsSection,
			firstRow: 0)
		
		switch contentState() {
			
		case
				.allowAccess, // Currently unused
				.loading:
			let newNumberOfRowsInCollectionsSection = (viewModel as? CollectionsViewModel)?.numberOfRows(
				forSection: indexOfCollectionsSection,
				contentState: contentState()) ?? 0
			let newInCollectionsSection
			= Array(0 ..< newNumberOfRowsInCollectionsSection).map { indexOfRow in
				IndexPath(row: indexOfRow, section: indexOfCollectionsSection)
			}
			switch oldInCollectionsSection.count {
			case 0: // Currently unused
				toDelete = oldInCollectionsSection // Empty
				toInsert = newInCollectionsSection
//				toReload = inAllSection
				toReload = []
				animationForReload = .none
			case 1: // "Allow Access" -> "Loading…"
				toDelete = []
				toInsert = []
//				toReload = inAllSection + newInCollectionsSection
				toReload = newInCollectionsSection
				animationForReload = .fade
			default: // "No Collections" -> "Loading…"
				toDelete = oldInCollectionsSection
				toInsert = newInCollectionsSection
//				toReload = inAllSection
				toReload = []
				animationForReload = .none
			}
			
		case .blank: // "Loading…" or "No Collections" -> blank
			toDelete = oldInCollectionsSection
			toInsert = []
//			toReload = inAllSection
			toReload = []
			animationForReload = .none
			
		case .noCollections:
			toDelete = oldInCollectionsSection
			
//			toReload = inAllSection
			toReload = []
			animationForReload = .none
			
			let newNumberOfRowsInCollectionsSection = (viewModel as? CollectionsViewModel)?.numberOfRows(
				forSection: indexOfCollectionsSection,
				contentState: contentState()) ?? 0
			let newIndexPaths = Array(0 ..< newNumberOfRowsInCollectionsSection).map { indexOfRow in
				IndexPath(row: indexOfRow, section: indexOfCollectionsSection)
			}
			toInsert = newIndexPaths
			
		case .oneOrMoreCollections: // Importing changes with existing Collections
			toDelete = []
			toInsert = []
			toReload = []
			animationForReload = .none
			
		}
		
		tableView.performBatchUpdates {
			tableView.deleteRows(at: toDelete, with: .middle)
			tableView.insertRows(at: toInsert, with: .middle)
			tableView.reloadRows(at: toReload, with: animationForReload)
		} completion: { _ in
			completion?()
		}
		
		switch contentState() {
		case .allowAccess, .loading, .blank, .noCollections:
			setEditing(false, animated: true)
		case .oneOrMoreCollections:
			break
		}
		
		didChangeRowsOrSelectedRows() // Refreshes the "Edit" button
	}
	
	// MARK: - Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		sortOptionsGrouped = [
			[.title],
			[.reverse],
		]
	}
	
	final override func viewDidLoad() {
		super.viewDidLoad()
		
		if albumMoverClipboard != nil {
		} else {
			DispatchQueue.main.async {
				self.integrateWithBuiltInMusicApp()
			}
		}
	}
	
	// Similar to viewDidLoad().
	final func didReceiveAuthorizationForMusicLibrary() {
		setUp()
		
		integrateWithBuiltInMusicApp()
	}
	
	private func integrateWithBuiltInMusicApp() {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		isImportingChanges = true // contentState() is now .loading or .oneOrMoreCollections (updating)
		refreshToReflectContentState {
			MusicLibraryManager.shared.setUpAndImportChanges() // You must finish LibraryTVC's beginObservingNotifications() before this, because we need to observe the notification after the import completes.
			PlayerManager.setUp() // This actually doesn't trigger refreshing the playback toolbar; refreshing after importing changes (above) does.
		}
	}
	
	// MARK: Setting Up UI
	
	final override func setUpUI() {
		// Choose our buttons for the navigation bar and toolbar before calling super, because super sets those buttons.
		if albumMoverClipboard != nil {
			viewingModeTopLeftButtons = []
			topRightButtons = [cancelMoveAlbumsButton]
			viewingModeToolbarButtons = [
				.flexibleSpace(),
				makeNewCollectionButton,
				.flexibleSpace(),
			]
		} else {
			viewingModeTopLeftButtons = [optionsButton]
		}
		
		super.setUpUI()
		
		if let albumMoverClipboard = albumMoverClipboard {
			navigationItem.prompt = albumMoverClipboard.navigationItemPrompt
		} else {
			editingModeToolbarButtons = [
//				combineButton, .flexibleSpace(),
				
				
				sortButton, .flexibleSpace(),
				floatToTopButton, .flexibleSpace(),
				sinkToBottomButton,
			]
		}
	}
	
	// MARK: Setup Events
	
	@IBAction func unwindToCollectionsFromEmptyCollection(_ unwindSegue: UIStoryboardSegue) {
	}
	
	final override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if albumMoverClipboard != nil {
		} else {
			if didMoveAlbums {
				// Replace this with refreshToReflectMusicLibrary()?
				refreshToReflectPlaybackState()
				refreshLibraryItemsWhenVisible()
				
				didMoveAlbums = false
			}
		}
	}
	
	final override func viewDidAppear(_ animated: Bool) {
		if albumMoverClipboard != nil {
			revertMakeNewCollectionIfEmpty()
		}
		
		super.viewDidAppear(animated)
	}
	
	// MARK: - Refreshing Buttons
	
	final override func refreshEditingButtons() {
		super.refreshEditingButtons()
		
		let collectionsViewModel = viewModel as? CollectionsViewModel
		let selectedIndexPaths = tableView.indexPathsForSelectedRowsNonNil
		combineButton.isEnabled = collectionsViewModel?.allowsCombine(
			selectedIndexPaths: selectedIndexPaths) ?? false
	}
	
	// MARK: - Navigation
	
	final override func prepare(
		for segue: UIStoryboardSegue,
		sender: Any?
	) {
		if
			segue.identifier == "Drill Down in Library",
			let albumsTVC = segue.destination as? AlbumsTVC,
			let selectedIndexPath = tableView.indexPathForSelectedRow
		{
			albumsTVC.albumMoverClipboard = albumMoverClipboard
			
			let container = viewModel.item(at: selectedIndexPath)
			let context = viewModel.context
			albumsTVC.viewModel = AlbumsViewModel(
				containers: [container],
				context: context,
				reflector: albumsTVC)
		}
	}
	
}
