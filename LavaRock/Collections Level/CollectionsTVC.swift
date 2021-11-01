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

final class CollectionsTVC:
	LibraryTVC,
	AlbumMover
{
	
	enum Section: Int, CaseIterable {
		case all
		case collections
	}
	
	// MARK: - Properties
	
	// Actions
	static let openCollectionSegueIdentifier = "Open Collection"
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
	
	// Controls
	@IBOutlet private var optionsButton: UIBarButtonItem!
	private lazy var combineButton: UIBarButtonItem = {
		let action = UIAction { _ in self.previewCombineSelectedCollectionsAndPresentDialog() }
		return UIBarButtonItem(
			title: LocalizedString.combine,
			primaryAction: action)
	}()
	
	// State
	var needsRemoveRowsInCollectionsSection = false
	var viewState: CollectionsViewState {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return .allowAccess
		}
		if needsRemoveRowsInCollectionsSection { // You must check this before checking isImportingChanges.
			return .wasLoadingOrNoCollections
		}
		if isImportingChanges {
			if viewModel.isEmpty() {
				return .loading
			} else {
				return .someCollections
			}
		} else {
			if viewModel.isEmpty() {
				return .noCollections
			} else {
				return .someCollections
			}
		}
	}
	var groupOfCollectionsBeforeCombining: GroupOfLibraryItems?
	var isPreviewingCombineCollections: Bool { groupOfCollectionsBeforeCombining != nil }
	
	// MARK: "Moving Albums" Mode
	
	// Controls
	private lazy var makeNewCollectionButton: UIBarButtonItem = {
		let action = UIAction { _ in self.previewMakeNewCollectionAndPresentDialog() }
		return UIBarButtonItem(
			systemItem: .add,
			primaryAction: action)
	}()
	
	// State
	var albumMoverClipboard: AlbumMoverClipboard?
	var didMoveAlbums = false
	
	// MARK: - Library State
	
	final func willRefreshLibraryItems() {
		switch viewState {
		case
				.loading,
				.noCollections:
			// We have placeholder rows in the Collections section. Remove them before `LibraryTVC` calls `setItemsAndMoveRows`.
			needsRemoveRowsInCollectionsSection = true // viewState is now .wasLoadingOrNoCollections
			reflectViewState()
			needsRemoveRowsInCollectionsSection = false // WARNING: viewState is now .loading or .noCollections, but the UI doesn't reflect that.
		case
				.allowAccess,
				.wasLoadingOrNoCollections,
				.someCollections:
			break
		}
	}
	
	final override func reflectNoItems() {
		// isImportingChanges is now false
		switch viewState {
		case .noCollections:
			reflectViewState()
		case
				.allowAccess,
				.loading,
				.wasLoadingOrNoCollections,
				.someCollections:
			break
		}
	}
	
	private func reflectViewState(
		completion: (() -> Void)? = nil
	) {
		let toDelete: [IndexPath]
		let toInsert: [IndexPath]
		let toReloadInCollectionsSection: [IndexPath]
		
		let indexOfCollectionsSection = FeatureFlag.allRow ? Section.collections.rawValue : 0
		let oldInCollectionsSection = tableView.indexPathsForRows(
			inSection: indexOfCollectionsSection,
			firstRow: 0)
		let newInCollectionsSection: [IndexPath] = {
			let numberOfRows = numberOfRows(forSection: indexOfCollectionsSection)
			let indicesOfRows = Array(0 ..< numberOfRows)
			return indicesOfRows.map { indexOfRow in
				IndexPath(row: indexOfRow, section: indexOfCollectionsSection)
			}
		}()
		
		switch viewState {
		case
				.allowAccess,
				.loading:
			if oldInCollectionsSection.count == newInCollectionsSection.count {
				toDelete = []
				toInsert = []
				toReloadInCollectionsSection = newInCollectionsSection
			} else {
				toDelete = oldInCollectionsSection // Can be empty
				toInsert = newInCollectionsSection
				toReloadInCollectionsSection = []
			}
		case .wasLoadingOrNoCollections:
			toDelete = oldInCollectionsSection
			toInsert = newInCollectionsSection // Empty
			toReloadInCollectionsSection = []
		case .noCollections:
			toDelete = oldInCollectionsSection
			toInsert = newInCollectionsSection
			toReloadInCollectionsSection = []
		case .someCollections: // Importing changes with existing Collections
			toDelete = []
			toInsert = []
			toReloadInCollectionsSection = []
		}
		
		tableView.performBatchUpdates {
			tableView.deleteRows(at: toDelete, with: .middle)
			tableView.insertRows(at: toInsert, with: .middle)
			if FeatureFlag.allRow {
				tableView.reloadSections([Section.all.rawValue], with: .none)
			}
			let animationForReload: UITableView.RowAnimation = toReloadInCollectionsSection.isEmpty ? .none : .fade
			tableView.reloadRows(at: toReloadInCollectionsSection, with: animationForReload)
		} completion: { _ in
			completion?()
		}
		
		switch viewState {
		case
				.allowAccess,
				.loading,
				.wasLoadingOrNoCollections,
				.noCollections:
			if isEditing {
				setEditing(false, animated: true)
			}
		case .someCollections:
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
		
		isImportingChanges = true // viewState is now .loading or .someCollections (updating)
		reflectViewState {
			MusicLibraryManager.shared.setUpAndImportChanges() // You must finish LibraryTVC's beginObservingNotifications() before this, because we need to observe the notification after the import completes.
			PlayerManager.setUp() // This actually doesn't trigger refreshing the playback toolbar; refreshing after importing changes (above) does.
		}
	}
	
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
	
	@IBAction private func unwindToCollectionsFromEmptyCollection(_ unwindSegue: UIStoryboardSegue) {
	}
	
	final override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if albumMoverClipboard != nil {
		} else {
			if didMoveAlbums {
				// Replace this with refreshLibraryItemsAndReflect()?
				reflectPlaybackStateAndNowPlayingItem()
				refreshLibraryItemsWhenVisible()
				
				didMoveAlbums = false
			}
		}
	}
	
	final override func viewDidAppear(_ animated: Bool) {
		if albumMoverClipboard != nil {
			revertMakeNewCollection()
		}
		
		super.viewDidAppear(animated)
	}
	
	// MARK: - Refreshing Buttons
	
	final override func refreshEditingButtons() {
		super.refreshEditingButtons()
		
		combineButton.isEnabled = allowsCombine()
	}
	
	private func allowsCombine() -> Bool {
		guard !viewModel.isEmpty() else {
			return false
		}
		
		return tableView.indexPathsForSelectedRowsNonNil.count >= 2
	}
	
	// MARK: - Navigation
	
	final override func prepare(
		for segue: UIStoryboardSegue,
		sender: Any?
	) {
		if
			segue.identifier == Self.openCollectionSegueIdentifier,
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
