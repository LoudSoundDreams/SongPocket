//
//  FoldersTVC.swift
//  LavaRock
//
//  Created by h on 2020-05-04.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import MediaPlayer

extension FoldersTVC: UIAdaptivePresentationControllerDelegate {
	func presentationControllerDidDismiss(
		_ presentationController: UIPresentationController
	) {
		revertCombine(thenSelect: presented_previewing_Combine_IndexPaths)
		presented_previewing_Combine_IndexPaths = []
	}
}
final class FoldersTVC:
	LibraryTVC,
	OrganizeAlbumsPreviewing
{
	enum Purpose {
		case willOrganizeAlbums(WillOrganizeAlbumsStickyNote)
		case organizingAlbums(OrganizeAlbumsClipboard)
		case movingAlbums(MoveAlbumsClipboard)
		case browsing
	}
	
	enum FoldersViewState {
		case allowAccess
		case loading
		case removingFolderRows
		case emptyDatabase
		case someFolders
	}
	static let emptyDatabaseInfoRow = 0
	
	// MARK: - Properties
	
	var presented_previewing_Combine_IndexPaths: [IndexPath] = []
	
	// Actions
	private(set) lazy var renameFocused = UIAccessibilityCustomAction(
		name: LRString.rename,
		actionHandler: renameFocusedHandler)
	private func renameFocusedHandler(
		_ sender: UIAccessibilityCustomAction
	) -> Bool {
		guard let focused = tableView.allIndexPaths().first(where: {
			let cell = tableView.cellForRow(at: $0)
			return cell?.accessibilityElementIsFocused() ?? false
		}) else {
			return false
		}
		promptRename(at: focused)
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
	var needsRemoveFolderRows = false
	var viewState: FoldersViewState {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return .allowAccess
		}
		if needsRemoveFolderRows { // You must check this before checking `isMergingChanges`.
			return .removingFolderRows
		}
		if isMergingChanges {
			if viewModel.isEmpty() {
				return .loading
			} else {
				return .someFolders
			}
		} else {
			if viewModel.isEmpty() {
				return .emptyDatabase
			} else {
				return .someFolders
			}
		}
	}
	var viewModelBeforeCombining: FoldersViewModel? = nil
	
	// MARK: “Organize albums” sheet
	
	// Data
	var willOrganizeAlbumsStickyNote: WillOrganizeAlbumsStickyNote? = nil
	var organizeAlbumsClipboard: OrganizeAlbumsClipboard? = nil
	
	// Controls
	private lazy var saveOrganizeButton = makeSaveOrganizeButton()
	
	// MARK: “Move albums” sheet
	
	// Data
	var moveAlbumsClipboard: MoveAlbumsClipboard? = nil
	
	// MARK: - View state
	
	func reflectViewState(
		runningBeforeCompletion beforeCompletion: (() -> Void)? = nil
	) async {
		let toDelete: [IndexPath]
		let toInsert: [IndexPath]
		let toReload: [IndexPath]
		
		let foldersSection = 0
		let oldIndexPaths = tableView.indexPathsForRows(inSection: foldersSection, firstRow: 0)
		let newIndexPaths: [IndexPath] = {
			let numberOfRows = numberOfRows(forSection: foldersSection)
			let indicesOfRows = Array(0 ..< numberOfRows)
			return indicesOfRows.map { row in
				IndexPath(row: row, section: foldersSection)
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
			case .removingFolderRows:
				toDelete = oldIndexPaths
				toInsert = newIndexPaths // Empty
				toReload = []
			case .emptyDatabase:
				toDelete = oldIndexPaths
				toInsert = newIndexPaths
				toReload = []
			case .someFolders: // Merging changes with existing folders
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
						.removingFolderRows,
						.emptyDatabase:
					if self.isEditing {
						self.setEditing(false, animated: true)
					}
				case .someFolders:
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
				AppleMusic.loadingIndicator = self
				
				NotificationCenter.default.addObserverOnce(
					self,
					selector: #selector(userUpdatedDatabase),
					name: .userUpdatedDatabase,
					object: nil)
		}
		
		title = LRString.folders
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
					floatButton,
					.flexibleSpace(),
					sinkButton,
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
	
	@IBAction private func unwindToFolders(_ unwindSegue: UIStoryboardSegue) {
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
				break
		}
		
		super.viewDidAppear(animated)
	}
	
	func prepareToIntegrateWithAppleMusic() async {
		isMergingChanges = true // `viewState` is now `.loading` or `.someFolders` (updating)
		await reflectViewState()
	}
	
	// MARK: - Library items
	
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
					.emptyDatabase:
				// We have placeholder rows in the Folders section. Remove them before `LibraryTVC` calls `setItemsAndMoveRows`.
				needsRemoveFolderRows = true // `viewState` is now `.removingFolderRows`
				Task {
					await reflectViewState(runningBeforeCompletion: {
						self.needsRemoveFolderRows = false // WARNING: `viewState` is now `.loading` or `.emptyDatabase`, but the UI doesn’t reflect that.
						
						super.freshenLibraryItems()
					})
				}
				return
			case
					.allowAccess,
					.removingFolderRows,
					.someFolders:
				break
		}
		
		if viewModelBeforeCombining != nil {
			// We’re previewing how the rows look after combining folders. Put everything back before `LibraryTVC` calls `setItemsAndMoveRows`.
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
		
		// Prevent the user from using any editing buttons while we’re animating combining folders, before we present the dialog.
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
		let foldersViewModel = viewModel as! FoldersViewModel
		
		guard
			let selectedIndexPath = tableView.indexPathForSelectedRow,
			let albumsTVC = segue.destination as? AlbumsTVC
		else { return }
		
		albumsTVC.organizeAlbumsClipboard = organizeAlbumsClipboard
		albumsTVC.moveAlbumsClipboard = moveAlbumsClipboard
		
		let selectedFolder = foldersViewModel.folderNonNil(atRow: selectedIndexPath.row)
		albumsTVC.viewModel = AlbumsViewModel(
			context: viewModel.context,
			folder: selectedFolder,
			prerows: {
				if case Purpose.movingAlbums = purpose {
					return [.moveHere]
				} else {
					return []
				}
			}()
		)
	}
}
