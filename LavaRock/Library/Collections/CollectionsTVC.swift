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

extension CollectionsTVC: UIAdaptivePresentationControllerDelegate {
	func presentationControllerDidDismiss(
		_ presentationController: UIPresentationController
	) {
		revertCombine(thenSelect: presented_previewing_Combine_IndexPaths)
		presented_previewing_Combine_IndexPaths = []
	}
}
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
	
	var presented_previewing_Combine_IndexPaths: [IndexPath] = []
	
	// Actions
	private(set) lazy var renameFocusedCollectionAction = UIAccessibilityCustomAction(
		name: LRString.rename,
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
	private lazy var combineButton = UIBarButtonItem(
		title: LRString.combine,
		primaryAction: UIAction { [weak self] _ in self?.previewCombine() })
	
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
	
	func reflectViewState(
		runningBeforeCompletion beforeCompletion: (() -> Void)? = nil
	) async {
		let toDelete: [IndexPath]
		let toInsert: [IndexPath]
		let toReload: [IndexPath]
		
		let collectionsSectionIndex = 0
		let oldIndexPaths = tableView.indexPathsForRows(
			inSection: collectionsSectionIndex,
			firstRow: 0)
		let newIndexPaths: [IndexPath] = {
			let numberOfRows = numberOfRows(forSection: collectionsSectionIndex)
			let indicesOfRows = Array(0 ..< numberOfRows)
			return indicesOfRows.map { row in
				IndexPath(row: row, section: collectionsSectionIndex)
			}
		}()
		
		switch viewState {
			case
					.allowAccess,
					.loading:
				if oldIndexPaths.count == newIndexPaths.count {
					toDelete = []
					toInsert = []
					toReload = newIndexPaths
				} else {
					toDelete = oldIndexPaths // Can be empty
					toInsert = newIndexPaths
					toReload = []
				}
			case .removingRowsInCollectionsSection:
				toDelete = oldIndexPaths
				toInsert = newIndexPaths // Empty
				toReload = []
			case .emptyPlaceholder:
				toDelete = oldIndexPaths
				toInsert = newIndexPaths
				toReload = []
			case .someCollections: // Merging changes with existing `Collection`s
				// Crashes after Reset Location & Privacy
				toDelete = []
				toInsert = []
				toReload = []
		}
		
		await tableView.performBatchUpdates__async {
			self.tableView.reloadRows(at: toReload, with: (toReload.isEmpty ? .none : .fade))
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
		
		sortCommandsGrouped = [
			[.folder_name],
			[.random, .reverse],
		]
	}
	
	private var needsIntegrateWithAppleMusic = false
	
	override func viewDidLoad() {
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
				
				needsIntegrateWithAppleMusic = true
		}
	}
	@objc private func userUpdatedDatabase() {
		reflectDatabase()
	}
	
	override func setUpBarButtons() {
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
				viewingModeTopLeftButtons = [
				]
				editingModeToolbarButtons = [
					combineButton,
					.flexibleSpace(),
					sortButton,
					.flexibleSpace(),
					floatToTopButton,
					.flexibleSpace(),
					sinkToBottomButton,
				]
		}
		
		super.setUpBarButtons()
		
		switch purpose {
			case .willOrganizeAlbums:
				showToolbar()
			case .organizingAlbums: // Should never run
				break
			case .movingAlbums:
				break
			case .browsing:
				showToolbar()
		}
		func showToolbar() {
			navigationController?.setToolbarHidden(false, animated: false)
		}
	}
	
	@IBAction private func unwindToCollectionsFromEmptyCollection(_ unwindSegue: UIStoryboardSegue) {
	}
	
	override func viewDidAppear(_ animated: Bool) {
		switch purpose {
			case .willOrganizeAlbums:
				break
			case .organizingAlbums:
				break
			case .movingAlbums:
				revertCreate()
			case .browsing:
				if needsIntegrateWithAppleMusic {
					needsIntegrateWithAppleMusic = false
					
					Task {
						await integrateWithAppleMusic()
					}
				}
		}
		
		super.viewDidAppear(animated)
	}
	
	func integrateWithAppleMusic() async {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return
		}
		
		isMergingChanges = true // `viewState` is now `.loading` or `.someCollections` (updating)
		await reflectViewState()
		
		AppleMusic.integrate()
	}
	
	// MARK: - Library Items
	
	override func freshenLibraryItems() {
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
	
	override func reflectViewModelIsEmpty() {
		Task {
			await reflectViewState()
		}
	}
	
	// MARK: - Freshening UI
	
	override func freshenEditingButtons() {
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
	
	override func prepare(
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
		
		let collection = collectionsViewModel.collectionNonNil(at: selectedIndexPath)
		albumsTVC.viewModel = AlbumsViewModel(
			context: viewModel.context,
			parentCollection: .exists(collection),
			prerowsInEachSection: {
				if case Purpose.movingAlbums = purpose {
					return [.moveHere]
				} else {
					return []
				}
			}()
		)
	}
}
