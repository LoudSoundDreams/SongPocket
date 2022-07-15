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
	enum Purpose {
		case willOrganizeAlbums(WillOrganizeAlbumsStickyNote)
		case organizingAlbums(OrganizeAlbumsClipboard)
		case movingAlbums(MoveAlbumsClipboard)
		case browsing
	}
	
	enum CollectionsViewState {
		case allowAccess
		case loading
		case removingRowsInCollectionsSection
		case emptyPlaceholder
		case someCollections
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
	var needsRemoveRowsInCollectionsSection = false
	var viewState: CollectionsViewState {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return .allowAccess
		}
		if needsRemoveRowsInCollectionsSection { // You must check this before checking `isMergingChanges`.
			return .removingRowsInCollectionsSection
		}
		if isMergingChanges {
			if viewModel.isEmpty() {
				return .loading
			} else {
				return .someCollections
			}
		} else {
			if viewModel.isEmpty() {
				return .emptyPlaceholder
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
	
	final func reflectViewState(
		runningBeforeCompletion beforeCompletion: (() -> Void)? = nil
	) async {
		let toDelete: [IndexPath]
		let toInsert: [IndexPath]
		let toReloadInCollectionsSection: [IndexPath]
		
		let collectionsSection = SectionIndex(0)
		let oldInCollectionsSection = tableView.indexPathsForRows(
			in: collectionsSection,
			first: RowIndex(0))
		let newInCollectionsSection: [IndexPath] = {
			let numberOfRows = numberOfRows(for: collectionsSection)
			let indicesOfRows = Array(0 ..< numberOfRows)
			return indicesOfRows.map { row in
				IndexPath(RowIndex(row), in: collectionsSection)
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
		case .removingRowsInCollectionsSection:
			toDelete = oldInCollectionsSection
			toInsert = newInCollectionsSection // Empty
			toReloadInCollectionsSection = []
		case .emptyPlaceholder:
			toDelete = oldInCollectionsSection
			toInsert = newInCollectionsSection
			toReloadInCollectionsSection = []
		case .someCollections: // Merging changes with existing `Collection`s
			// TO DO: Is this right?
			toDelete = []
			toInsert = []
			toReloadInCollectionsSection = []
		}
		
		let _ = await tableView.update__async {
			let animationForReload: UITableView.RowAnimation = toReloadInCollectionsSection.isEmpty ? .none : .fade
			self.tableView.reloadRows(at: toReloadInCollectionsSection, with: animationForReload)
			self.tableView.deleteRows(at: toDelete, with: .middle)
			self.tableView.insertRows(at: toInsert, with: .middle)
		} runningBeforeContinuation: {
			switch self.viewState {
			case
					.allowAccess,
					.loading,
					.removingRowsInCollectionsSection,
					.emptyPlaceholder:
				if self.isEditing {
					self.setEditing(false, animated: true)
				}
			case .someCollections:
				break
			}
			
			self.didChangeRowsOrSelectedRows() // Freshens “Edit” button
			
			beforeCompletion?()
		}
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
		case .organizingAlbums: // Should never run
			break
		case .movingAlbums(let clipboard):
			navigationItem.prompt = clipboard.prompt
		case .browsing:
			NotificationCenter.default.addObserverOnce(
				self,
				selector: #selector(userUpdatedDatabase),
				name: .userUpdatedDatabase,
				object: nil)
			
			Task {
				await integrateWithMusicApp()
			}
		}
	}
	@objc private func userUpdatedDatabase() {
		reflectDatabase()
	}
	
	final override func setUpBarButtons() {
		switch purpose {
		case .willOrganizeAlbums:
			viewingModeTopLeftButtons = [
			]
			viewingModeTopRightButtons = [
				cancelAndDismissButton,
			]
			viewingModeToolbarButtons = [
				.flexibleSpace(),
				saveOrganizeButton,
				.flexibleSpace(),
			]
		case .organizingAlbums: // Should never run
			break
		case .movingAlbums:
			viewingModeTopLeftButtons = [
			]
			viewingModeTopRightButtons = [
				cancelAndDismissButton,
			]
		case .browsing:
			let optionsButton: UIBarButtonItem = Enabling.swiftUI__options
			? optionsButton__SwiftUI
			: optionsButton__UIKit
			viewingModeTopLeftButtons = [
				optionsButton,
			]
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
			navigationController?.setToolbarHidden(false, animated: false)
		case .organizingAlbums: // Should never run
			break
		case .movingAlbums:
			break
		case .browsing:
			navigationController?.setToolbarHidden(false, animated: false) // TO DO: Move this to `LibraryNC`
		}
	}
	
	final func integrateWithMusicApp() async {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		isMergingChanges = true // `viewState` is now `.loading` or `.someCollections` (updating)
		await reflectViewState()
		
		MusicFolder.shared.setUpAndMergeChanges() // You must finish `LibraryTVC.beginObservingNotifications` before this, because we need to observe the notification after the merge completes.
		TapeDeck.shared.setUp()
	}
	
	@IBAction private func unwindToCollectionsFromEmptyCollection(_ unwindSegue: UIStoryboardSegue) {
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
	
	@IBAction private func presentOptions__UIKit(_ sender: UIBarButtonItem) {
		presentOptions()
	}
	
	@IBAction private func presentOptions__SwiftUI(_ sender: UIBarButtonItem) {
		presentOptions()
	}
	
	private func presentOptions() {
		let viewController: UIViewController
		= Enabling.swiftUI__options
		? UIHostingController(rootView: OptionsView())
		: UIStoryboard(name: "Options", bundle: nil)
			.instantiateInitialViewController()!
		viewController.modalPresentationStyle = .formSheet
		present(viewController, animated: true)
	}
	
	// MARK: - Library Items
	
	final override func shouldDismissAllViewControllersBeforeFreshenLibraryItems() -> Bool {
		if
			(presentedViewController as? UINavigationController)?.viewControllers.first is OptionsTVC
				|| presentedViewController is UIHostingController<OptionsView>
		{
			return false
		}
		
		return super.shouldDismissAllViewControllersBeforeFreshenLibraryItems()
	}
	
	final override func freshenLibraryItems() {
		switch purpose {
		case .willOrganizeAlbums:
			return
		case .organizingAlbums:
			return
		case .movingAlbums:
			return
		case .browsing:
			break
		}
		
		switch viewState {
		case
				.loading,
				.emptyPlaceholder:
			// We have placeholder rows in the Collections section. Remove them before `LibraryTVC` calls `setItemsAndMoveRows`.
			needsRemoveRowsInCollectionsSection = true // `viewState` is now `.removingRowsInCollectionsSection`
			Task {
				await reflectViewState(runningBeforeCompletion: {
					self.needsRemoveRowsInCollectionsSection = false // WARNING: `viewState` is now `.loading` or `.emptyPlaceholder`, but the UI doesn’t reflect that.
					
					super.freshenLibraryItems()
				})
			}
			return
		case
				.allowAccess,
				.removingRowsInCollectionsSection,
				.someCollections:
			break
		}
		
		if viewModelBeforeCombining != nil {
			// We’re previewing how the rows look after combining `Collection`s. Put everything back before `LibraryTVC` calls `setItemsAndMoveRows`.
			revertCombine(thenSelect: [])
		}
		
		super.freshenLibraryItems()
	}
	
	final override func reflectViewModelIsEmpty() {
		Task {
			await reflectViewState()
		}
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
		return tableView.selectedIndexPaths.count >= 2
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
