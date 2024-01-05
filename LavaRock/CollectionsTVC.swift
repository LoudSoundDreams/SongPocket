//
//  CollectionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-05-04.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import MusicKit
import SwiftUI

final class CollectionsTVC: LibraryTVC {
	enum Purpose {
		case movingAlbums(MoveAlbumsClipboard)
		case browsing
	}
	
	enum CollectionsViewState {
		case allowAccess
		case loading
		case emptyDatabase
		case someCollections
	}
	
	// MARK: - Properties
	
	// Controls
	private lazy var arrangeCollectionsButton = UIBarButtonItem(
		title: LRString.sort,
		image: UIImage(systemName: "arrow.up.arrow.down")
	)
	
	// Purpose
	var purpose: Purpose {
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
			case .movingAlbums: break
			case .browsing:
				AppleMusic.loadingIndicator = self
				
				NotificationCenter.default.addObserverOnce(self, selector: #selector(reflectDatabase), name: .LRUserUpdatedDatabase, object: nil)
		}
		
		navigationItem.backButtonDisplayMode = .minimal
	}
	
	override func setUpBarButtons() {
		switch purpose {
			case .movingAlbums:
				viewingModeTopLeftButtons = [
					UIBarButtonItem(
						systemItem: .close,
						primaryAction: UIAction { [weak self] _ in
							self?.dismiss(animated: true)
						}
					),
				]
				viewingModeTopRightButtons = [
					UIBarButtonItem(
						systemItem: .add,
						primaryAction: UIAction { [weak self] _ in self?.createAndOpen() }
					),
				]
			case .browsing:
				editingModeToolbarButtons = [
					arrangeCollectionsButton, .flexibleSpace(),
					floatButton, .flexibleSpace(),
					sinkButton, .flexibleSpace(),
					editButtonItem,
				]
		}
		
		super.setUpBarButtons()
		
		switch purpose {
			case .movingAlbums: break
			case .browsing:
				navigationController?.setToolbarHidden(false, animated: false)
		}
	}
	
	@IBAction private func unwindToCollections(_ unwindSegue: UIStoryboardSegue) {}
	
	override func viewIsAppearing(_ animated: Bool) {
		super.viewIsAppearing(animated)
		switch purpose {
			case .movingAlbums: break
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
			case .browsing: break
		}
		super.viewDidAppear(animated)
	}
	private var forBrowsingAndHasFirstAppeared = false
	
	func prepareToIntegrateWithAppleMusic() async {
		isMergingChanges = true // `viewState` is now `.loading` or `.someCollections` (updating)
		reflectViewState()
	}
	
	func requestAccessToAppleMusic() async {
		switch MusicAuthorization.currentStatus {
			case .authorized: break // Should never run
			case .notDetermined:
				let response = await MusicAuthorization.request()
				
				switch response {
					case .denied, .restricted, .notDetermined: break
					case .authorized: await AppleMusic.integrateIfAuthorized()
					@unknown default: break
				}
			case .denied, .restricted:
				if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
					let _ = await UIApplication.shared.open(settingsURL)
				}
			@unknown default: break
		}
	}
	
	// MARK: - Library items
	
	override func freshenLibraryItems() {
		switch purpose {
			case .movingAlbums: return
			case .browsing: break
		}
		
		switch viewState {
			case .loading, .emptyDatabase:
				reflectViewState()
				super.freshenLibraryItems()
				return
			case .allowAccess, .someCollections: break
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
		
		arrangeCollectionsButton.isEnabled = allowsArrange()
		arrangeCollectionsButton.menu = createArrangeMenu()
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
		
		albumsTVC.moveAlbumsClipboard = moveAlbumsClipboard
		
		let selectedCollection = collectionsViewModel.collectionNonNil(atRow: selectedIndexPath.row)
		albumsTVC.viewModel = AlbumsViewModel(
			collection: selectedCollection,
			context: viewModel.context)
	}
}
