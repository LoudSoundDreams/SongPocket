//
//  CollectionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-05-04.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import MusicKit

extension CollectionsTVC: UIAdaptivePresentationControllerDelegate {
	func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
		revertCombine(thenSelect: presented_previewing_Combine_IndexPaths)
		presented_previewing_Combine_IndexPaths = []
	}
}
final class CollectionsTVC: LibraryTVC {
	enum Purpose {
		case willOrganizeAlbums
		case organizingAlbums(OrganizeAlbumsClipboard)
		case movingAlbums(MoveAlbumsClipboard)
		case browsing
	}
	
	enum CollectionsViewState {
		case allowAccess
		case loading
		case emptyDatabase
		case someCollections
	}
	static let emptyDatabaseInfoRow = 0
	
	// MARK: - Properties
	
	var presented_previewing_Combine_IndexPaths: [IndexPath] = []
	
	// Controls
	private lazy var combineButton = UIBarButtonItem(
		title: LRString.combine,
		primaryAction: UIAction { [weak self] _ in self?.previewCombine() })
	private lazy var arrangeCollectionsButton = UIBarButtonItem(title: LRString.arrange)
	
	// Purpose
	var purpose: Purpose {
		if let clipboard = organizeAlbumsClipboard { return .organizingAlbums(clipboard) }
		if willOrganizeAlbums { return .willOrganizeAlbums }
		if let clipboard = moveAlbumsClipboard { return .movingAlbums(clipboard) }
		return .browsing
	}
	
	// State
	var viewState: CollectionsViewState {
		guard MusicAuthorization.currentStatus == .authorized else {
			return .allowAccess
		}
		guard viewModel.isEmpty() else {
			return .someCollections
		}
		if isMergingChanges {
			return .loading
		}
		return .emptyDatabase
	}
	var viewModelBeforeCombining: CollectionsViewModel? = nil
	
	// MARK: “Organize albums” sheet
	
	// Data
	var willOrganizeAlbums = false
	var organizeAlbumsClipboard: OrganizeAlbumsClipboard? = nil
	
	// MARK: “Move albums” sheet
	
	// Data
	var moveAlbumsClipboard: MoveAlbumsClipboard? = nil
	
	// MARK: -
	
	func reflectViewState() {
		let toDelete: [IndexPath] = {
			switch viewState {
				case .allowAccess, .loading, .emptyDatabase:
					return tableView.indexPathsForRows(inSection: 0, firstRow: 0)
				case .someCollections: // Merging changes with existing collections
					// Crashes after Reset Location & Privacy
					return []
			}
		}()
		tableView.performBatchUpdates {
			tableView.deleteRows(at: toDelete, with: .middle)
		}
		
		switch viewState {
			case .allowAccess, .loading, .emptyDatabase:
				if isEditing {
					setEditing(false, animated: true)
				}
			case .someCollections: break
		}
		
		didChangeRowsOrSelectedRows() // Freshens “Edit” button
	}
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		switch purpose {
			case .willOrganizeAlbums, .organizingAlbums: break
			case .movingAlbums(let clipboard):
				navigationItem.prompt = clipboard.prompt
			case .browsing:
				AppleMusic.loadingIndicator = self
				
				NotificationCenter.default.addObserverOnce(self, selector: #selector(userUpdatedDatabase), name: .LRUserUpdatedDatabase, object: nil)
		}
		
		navigationItem.backButtonDisplayMode = .minimal
		title = LRString.crates
	}
	@objc private func userUpdatedDatabase() { reflectDatabase() }
	
	override func setUpBarButtons() {
		switch purpose {
			case .willOrganizeAlbums:
				viewingModeTopLeftButtons = [
					UIBarButtonItem(systemItem: .close, primaryAction: UIAction { [weak self] _ in
						self?.dismiss(animated: true)
					}),
				]
				viewingModeTopRightButtons = [
					{
						let saveOrganizeButton = UIBarButtonItem(systemItem: .save, primaryAction: UIAction { [weak self] _ in
							self?.commitOrganize()
						})
						saveOrganizeButton.style = .done
						return saveOrganizeButton
					}(),
				]
			case .organizingAlbums: // Should never run
				break
			case .movingAlbums:
				viewingModeTopLeftButtons = [
					UIBarButtonItem(systemItem: .close, primaryAction: UIAction { [weak self] _ in
						self?.dismiss(animated: true)
					}),
				]
				viewingModeTopRightButtons = [
					UIBarButtonItem(systemItem: .add, primaryAction: UIAction { [weak self] _ in
						self?.createAndOpen()
					}),
				]
			case .browsing:
				viewingModeTopLeftButtons = []
				viewingModeTopRightButtons = [editButtonItem]
				editingModeToolbarButtons = [
					combineButton, .flexibleSpace(),
					arrangeCollectionsButton, .flexibleSpace(),
					floatButton, .flexibleSpace(),
					sinkButton,
				]
		}
		
		super.setUpBarButtons()
		
		switch purpose {
			case .willOrganizeAlbums, .organizingAlbums, .movingAlbums: break
			case .browsing:
				navigationController?.setToolbarHidden(false, animated: false)
		}
	}
	
	@IBAction private func unwindToCollections(_ unwindSegue: UIStoryboardSegue) {}
	
	override func viewIsAppearing(_ animated: Bool) {
		super.viewIsAppearing(animated)
		switch purpose {
			case .movingAlbums, .willOrganizeAlbums, .organizingAlbums: break
			case .browsing:
				if !forBrowsingAndHasFirstAppeared {
					forBrowsingAndHasFirstAppeared = true
					
					// As of iOS 16.6.1, the build setting “Global Accent Color Name” doesn’t apply to (UIKit) alerts or action sheets.
					view.window!.tintColor = UIColor(named: "denim")!
				}
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		switch purpose {
			case .movingAlbums:
				revertCreate()
			case .willOrganizeAlbums, .organizingAlbums, .browsing: 
				break
		}
		super.viewDidAppear(animated)
	}
	private var forBrowsingAndHasFirstAppeared = false
	
	func prepareToIntegrateWithAppleMusic() async {
		isMergingChanges = true // `viewState` is now `.loading` or `.someCollections` (updating)
		reflectViewState()
	}
	
	// MARK: - Library items
	
	private func commitOrganize() {
		guard
			let clipboard = organizeAlbumsClipboard,
			!clipboard.didAlreadyCommitOrganize
		else { return }
		
		clipboard.didAlreadyCommitOrganize = true
		
		viewModel.context.tryToSave()
		viewModel.context.parent!.tryToSave()
		
		NotificationCenter.default.post(name: .LRUserUpdatedDatabase, object: nil)
		
		dismiss(animated: true)
		NotificationCenter.default.post(name: .LROrganizedAlbums, object: nil)
	}
	
	override func freshenLibraryItems() {
		switch purpose {
			case .willOrganizeAlbums, .organizingAlbums, .movingAlbums: return
			case .browsing: break
		}
		
		switch viewState {
			case .loading, .emptyDatabase:
				reflectViewState()
				super.freshenLibraryItems()
				return
			case .allowAccess, .someCollections: break
		}
		
		if viewModelBeforeCombining != nil {
			// We’re previewing how the rows look after combining collections. Put everything back before `LibraryTVC` calls `setViewModelAndMoveAndDeselectRowsAndShouldContinue`.
			revertCombine(thenSelect: [])
		}
		
		super.freshenLibraryItems()
	}
	
	override func reflectViewModelIsEmpty() {
		reflectViewState()
	}
	
	// MARK: - Freshening UI
	
	override func freshenEditingButtons() {
		super.freshenEditingButtons()
		
		switch viewState {
			case .allowAccess, .loading, .emptyDatabase:
				editButtonItem.isEnabled = false
			case .someCollections: break
		}
		
		combineButton.isEnabled = allowsCombine()
		
		arrangeCollectionsButton.isEnabled = allowsArrange()
		arrangeCollectionsButton.menu = createArrangeMenu()
		
		// Prevent the user from using any editing buttons while we’re animating combining collections, before we present the dialog.
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
	private static let arrangeCommands: [[ArrangeCommand]] = [
		[.collection_name],
		[.random, .reverse],
	]
	private func createArrangeMenu() -> UIMenu {
		let setOfCommands: Set<ArrangeCommand> = Set(Self.arrangeCommands.flatMap { $0 })
		let elementsGrouped: [[UIMenuElement]] = Self.arrangeCommands.reversed().map {
			$0.reversed().map { command in
				return command.createMenuElement(
					enabled:
						unsortedRowsToArrange().count >= 2
					&& setOfCommands.contains(command)
				) { [weak self] in
					self?.arrangeSelectedOrAll(by: command)
				}
			}
		}
		let inlineSubmenus = elementsGrouped.map {
			return UIMenu(options: .displayInline, children: $0)
		}
		return UIMenu(children: inlineSubmenus)
	}
	
	// MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		let collectionsViewModel = viewModel as! CollectionsViewModel
		
		guard
			let selectedIndexPath = tableView.indexPathForSelectedRow,
			let albumsTVC = segue.destination as? AlbumsTVC
		else { return }
		
		albumsTVC.organizeAlbumsClipboard = organizeAlbumsClipboard
		albumsTVC.moveAlbumsClipboard = moveAlbumsClipboard
		
		let selectedCollection = collectionsViewModel.collectionNonNil(atRow: selectedIndexPath.row)
		albumsTVC.viewModel = AlbumsViewModel(
			collection: selectedCollection,
			context: viewModel.context)
	}
}
