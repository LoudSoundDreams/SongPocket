//
//  CollectionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-05-04.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import MediaPlayer
import SwiftUI

final class CollectionsTVC:
	LibraryTVC,
	OrganizeAlbumsPreviewing
{
	enum CollectionsViewState {
		case allowAccess
		case loading
		case wasLoadingOrNoCollections
		case noCollections
		case someCollections
	}
	
	enum Purpose {
		case willOrganizeAlbums(WillOrganizeAlbumsStickyNote)
		case organizingAlbums(OrganizeAlbumsClipboard)
		case movingAlbums(MoveAlbumsClipboard)
		case browsing
	}
	
	// MARK: - Properties
	
	// Actions
	private(set) lazy var renameFocusedCollectionAction = UIAccessibilityCustomAction(
		name: LocalizedString.rename,
		actionHandler: renameFocusedCollectionHandler)
	private func renameFocusedCollectionHandler(
		_ sender: UIAccessibilityCustomAction
	) -> Bool {
		let indexPathsOfAllCollections = viewModel.indexPathsForAllItems()
		guard let focusedIndexPath = indexPathsOfAllCollections.first(where: {
			let cell = tableView.cellForRow(at: $0)
			return cell?.accessibilityElementIsFocused() ?? false
		}) else {
			return false
		}
		promptRename(at: focusedIndexPath)
		return true
	}
	
	// Controls
	@IBOutlet private var optionsButton__UIKit: UIBarButtonItem!
	@IBOutlet private var optionsButton__SwiftUI: UIBarButtonItem!
	private lazy var combineButton = UIBarButtonItem(
		title: LocalizedString.combine,
		primaryAction: UIAction { [weak self] _ in self?.previewCombineAndPrompt() })
	
	// Purpose
	var purpose: Purpose {
		if let clipboard = organizeAlbumsClipboard {
			return .organizingAlbums(clipboard)
		} else if let stickyNote = willOrganizeAlbumsStickyNote {
			return .willOrganizeAlbums(stickyNote)
		} else if let clipboard = moveAlbumsClipboard {
			return .movingAlbums(clipboard)
		}
		return .browsing
	}
	
	// State
	private var needsRemoveRowsInCollectionsSection = false
	var viewState: CollectionsViewState {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return .allowAccess
		}
		if needsRemoveRowsInCollectionsSection { // You must check this before checking `isMergingChanges`.
			return .wasLoadingOrNoCollections
		}
		if isMergingChanges {
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
	var viewModelBeforeCombining: CollectionsViewModel? = nil
	
	// MARK: “Organize Albums” Sheet
	
	// Data
	var willOrganizeAlbumsStickyNote: WillOrganizeAlbumsStickyNote? = nil
	var organizeAlbumsClipboard: OrganizeAlbumsClipboard? = nil
	
	// Controls
	private lazy var saveOrganizeButton = makeSaveOrganizeButton()
	
	// MARK: “Move Albums” Sheet
	
	// Data
	var moveAlbumsClipboard: MoveAlbumsClipboard? = nil
	
	// MARK: - View State
	
	final func willFreshenLibraryItems() {
		switch viewState {
		case
				.loading,
				.noCollections:
			// We have placeholder rows in the Collections section. Remove them before `LibraryTVC` calls `setItemsAndMoveRows`.
			needsRemoveRowsInCollectionsSection = true // `viewState` is now `.wasLoadingOrNoCollections`
			reflectViewState()
			needsRemoveRowsInCollectionsSection = false // WARNING: `viewState` is now `.loading` or `.noCollections`, but the UI doesn’t reflect that.
		case
				.allowAccess,
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
		
		let indexOfCollectionsSection = 0
		let oldInCollectionsSection = tableView.indexPathsForRows(
			inSection: indexOfCollectionsSection,
			firstRow: 0)
		let newInCollectionsSection: [IndexPath] = {
			let numberOfRows = numberOfRows(forSection: indexOfCollectionsSection)
			let indicesOfRows = Array(0 ..< numberOfRows)
			return indicesOfRows.map { indexOfRow in
				IndexPath(row: indexOfRow, section: indexOfCollectionsSection)
			}}()
		
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
		case .someCollections: // Merging changes with existing `Collection`s
			toDelete = []
			toInsert = []
			toReloadInCollectionsSection = []
		}
		
		tableView.performBatchUpdates {
			let animationForReload: UITableView.RowAnimation = toReloadInCollectionsSection.isEmpty ? .none : .fade
			tableView.reloadRows(at: toReloadInCollectionsSection, with: animationForReload)
			tableView.deleteRows(at: toDelete, with: .middle)
			tableView.insertRows(at: toInsert, with: .middle)
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
		
		didChangeRowsOrSelectedRows() // Freshens “Edit” button
	}
	
	// MARK: - Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		sortOptionsGrouped = [
			[.title],
			[.shuffle, .reverse],
		]
	}
	
	final override func viewDidLoad() {
		super.viewDidLoad()
		
		switch purpose {
		case .willOrganizeAlbums(let stickyNote):
			navigationItem.prompt = stickyNote.prompt
		case .organizingAlbums:
			// Should never run
			break
		case .movingAlbums(let clipboard):
			navigationItem.prompt = clipboard.prompt
		case .browsing:
			Task {
				integrateWithMusicApp()
			}
			
			switch purpose {
			case .willOrganizeAlbums:
				break
			case .organizingAlbums:
				break
			case .movingAlbums:
				break
			case .browsing:
				NotificationCenter.default.addObserverOnce(
					self,
					selector: #selector(userDidUpdateDatabase),
					name: .LRUserDidUpdateDatabase,
					object: nil)
			}
		}
	}
	@objc private func userDidUpdateDatabase() { reflectDatabase() }
	
	final override func setUpBarButtons() {
		switch purpose {
		case .willOrganizeAlbums:
			viewingModeTopLeftButtons = []
			viewingModeToolbarButtons = [
				.flexibleSpace(),
				saveOrganizeButton,
				.flexibleSpace(),
			]
			if Enabling.playerScreen {
				editingModeToolbarButtons = viewingModeToolbarButtons // A hack
			}
		case .organizingAlbums:
			// Should never run
			break
		case .movingAlbums:
			viewingModeTopLeftButtons = []
		case .browsing:
			if Enabling.swiftUI__options {
				viewingModeTopLeftButtons = [optionsButton__SwiftUI]
			} else {
				viewingModeTopLeftButtons = [optionsButton__UIKit]
			}
			editingModeToolbarButtons = [
				combineButton, .flexibleSpace(),
				sortButton, .flexibleSpace(),
				floatToTopButton, .flexibleSpace(),
				sinkToBottomButton,
			]
		}
		
		super.setUpBarButtons()
		
		switch purpose {
		case .willOrganizeAlbums:
			navigationItem.rightBarButtonItem = cancelAndDismissButton
			navigationController?.setToolbarHidden(false, animated: false)
		case .organizingAlbums:
			// Should never run
			break
		case .movingAlbums:
			navigationItem.rightBarButtonItem = cancelAndDismissButton
		case .browsing:
			navigationItem.rightBarButtonItem = editButtonItem
			if Enabling.playerScreen {
			} else {
				navigationController?.setToolbarHidden(false, animated: false)
			}
		}
	}
	
	final func integrateWithMusicApp() {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		isMergingChanges = true // `viewState` is now `.loading` or `.someCollections` (updating)
		reflectViewState {
			MusicLibraryWatcher.shared.setUpAndMergeChanges() // You must finish `LibraryTVC.beginObservingNotifications` before this, because we need to observe the notification after the merge completes.
			TapeDeck.shared.setUp()
		}
	}
	
	@IBAction private func unwindToCollectionsFromEmptyCollection(_ unwindSegue: UIStoryboardSegue) {
		if Enabling.playerScreen {
			navigationController?.setToolbarHidden(true, animated: true)
		}
	}
	
	final override func viewDidAppear(_ animated: Bool) {
		switch purpose {
		case .willOrganizeAlbums:
			break
		case .organizingAlbums:
			break
		case .movingAlbums:
			revertCreate()
		case .browsing:
			break
		}
		
		super.viewDidAppear(animated)
	}
	
	// MARK: - Setting Items
	
	final override func reflectViewModelIsEmpty() {
		reflectViewState()
	}
	
	// MARK: - Freshening UI
	
	final override func freshenEditingButtons() {
		super.freshenEditingButtons()
		
		combineButton.isEnabled = allowsCombine()
		
		// Prevent the user from using any editing buttons while we’re animating combining `Collection`s, before we present the dialog.
		if viewModelBeforeCombining != nil {
			editingModeToolbarButtons.forEach { $0.isEnabled = false }
		}
	}
	
	private func allowsCombine() -> Bool {
		guard !viewModel.isEmpty() else {
			return false
		}
		return tableView.indexPathsForSelectedRowsNonNil.count >= 2
	}
	
	// MARK: - Navigation
	
	@IBAction private func openOptions_SwiftUI(_ sender: UIBarButtonItem) {
		let hostingController = UIHostingController(rootView: OptionsView())
		hostingController.modalPresentationStyle = .formSheet
		present(hostingController, animated: true)
	}
	
	final override func prepare(
		for segue: UIStoryboardSegue,
		sender: Any?
	) {
		let collectionsViewModel = viewModel as! CollectionsViewModel
		
		guard
			let selectedIndexPath = tableView.indexPathForSelectedRow,
			let albumsTVC = segue.destination as? AlbumsTVC
		else { return }
		
		albumsTVC.organizeAlbumsClipboard = organizeAlbumsClipboard
		albumsTVC.moveAlbumsClipboard = moveAlbumsClipboard
		
		let prerowsInEachSection: [AlbumsViewModel.Prerow] = {
			switch purpose {
			case .willOrganizeAlbums:
				return []
			case .organizingAlbums:
				return []
			case .movingAlbums:
				return [.moveHere]
			case .browsing:
				return []
			}}()
		if Enabling.multicollection {
			let collection = collectionsViewModel.collectionNonNil(at: selectedIndexPath)
			let indexOfSelectedCollection = collection.index
			albumsTVC.indexOfOpenedCollection = Int(indexOfSelectedCollection)
			
			albumsTVC.viewModel = AlbumsViewModel(
				viewContainer: .library,
				context: viewModel.context,
				prerowsInEachSection: prerowsInEachSection)
		} else {
			let collection = collectionsViewModel.collectionNonNil(at: selectedIndexPath)
			albumsTVC.viewModel = AlbumsViewModel(
				viewContainer: .container(collection),
				context: viewModel.context,
				prerowsInEachSection: prerowsInEachSection)
		}
	}
}
