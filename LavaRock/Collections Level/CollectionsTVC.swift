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
	
	// MARK: - Types
	
	enum ContentState {
		case allowAccess
		case loading
		case blank
		case noCollections
		case oneOrMoreCollections
	}
	
	// MARK: - Properties
	
	// "Constants"
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
	
	// Variables
	var shouldContentStateBeBlank = false
	var sectionOfCollectionsBeforeCombining: SectionOfLibraryItems?
	
	// MARK: "Moving Albums" Mode
	
	// Variables
	var albumMoverClipboard: AlbumMoverClipboard?
	var didMoveAlbums = false
	
	// MARK: - Content State
	
	final func contentState() -> ContentState {
		if MPMediaLibrary.authorizationStatus() != .authorized {
			return .allowAccess
		}
		if shouldContentStateBeBlank { // You must check shouldContentStateBeBlank before checking isImportingChanges.
			return .blank
		}
		if isImportingChanges {
			if sectionOfLibraryItems.isEmpty() {
				return .loading
			} else {
				return .oneOrMoreCollections
			}
		} else {
			if sectionOfLibraryItems.isEmpty() {
				return .noCollections
			} else {
				return .oneOrMoreCollections
			}
		}
	}
	
	final func prepareToRefreshLibraryItems() {
		if contentState() == .loading || contentState() == .noCollections {
			shouldContentStateBeBlank = true // contentState() is now .blank
			refreshToReflectContentState()
			shouldContentStateBeBlank = false // WARNING: Unsafe; contentState() is now .loading, but the UI doesn't reflect that.
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
		let indexPathsToDelete: [IndexPath]
		let indexPathsToInsert: [IndexPath]
		let indexPathsToReload: [IndexPath]
		
		let oldIndexPaths = tableView.allIndexPaths()
		
		switch contentState() {
			
		case
				.allowAccess, // Currently unused
				.loading:
			let sectionForCollections = 0
			let newNumberOfRowsInSectionForCollections = newNumberOfRows(forSection: sectionForCollections)
			let newIndexPaths = Array(0..<newNumberOfRowsInSectionForCollections).map {
				IndexPath(row: $0, section: sectionForCollections)
			}
			switch tableView.numberOfRows(inSection: sectionForCollections) {
			case 0: // Currently unused
				indexPathsToDelete = oldIndexPaths // Empty
				indexPathsToInsert = newIndexPaths
				indexPathsToReload = []
			case 1: // "Allow Access" -> "Loading…"
				indexPathsToDelete = []
				indexPathsToInsert = []
				indexPathsToReload = newIndexPaths
			default: // "No Collections" -> "Loading…"
				indexPathsToDelete = oldIndexPaths
				indexPathsToInsert = newIndexPaths
				indexPathsToReload = []
			}
			
		case .blank: // "Loading…" or "No Collections" -> blank
			indexPathsToDelete = oldIndexPaths
			indexPathsToInsert = []
			indexPathsToReload = []
			
		case .noCollections:
			indexPathsToDelete = oldIndexPaths
			indexPathsToReload = []
			
			let sectionForCollections = 0
			let newNumberOfRows = newNumberOfRows(forSection: sectionForCollections)
			let newIndexPaths = Array(0..<newNumberOfRows).map {
				IndexPath(row: $0, section: sectionForCollections)
			}
			indexPathsToInsert = newIndexPaths
			
		case .oneOrMoreCollections: // Importing changes with existing Collections
			indexPathsToDelete = []
			indexPathsToInsert = []
			indexPathsToReload = []
			
		}
		
		tableView.performBatchUpdates {
			tableView.deleteRows(at: indexPathsToDelete, with: .middle)
			tableView.insertRows(at: indexPathsToInsert, with: .middle)
			tableView.reloadRows(at: indexPathsToReload, with: .fade)
		} completion: { _ in
			completion?()
		}
		
		if contentState() == .noCollections {
			setEditing(false, animated: true)
		}
		
		didChangeRowsOrSelectedRows() // Disables the "Edit" button if contentState() == .noCollections
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
//				combineButton,
//				.flexibleSpace(),
				
				sortButton,
				.flexibleSpace(),
				
				floatToTopButton,
				.flexibleSpace(),
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
				refreshLibraryItemsWhenVisible() // Note: This re-animates adding the Collections we made while moving Albums, even though we already saw them get added in the "move Albums to…" sheet.
				
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
		
		combineButton.isEnabled = allowsCombine()
	}
	
	// MARK: - Navigation
	
	final override func prepare(
		for segue: UIStoryboardSegue,
		sender: Any?
	) {
		if
			segue.identifier == "Drill Down in Library",
			let albumsTVC = segue.destination as? AlbumsTVC
		{
			albumsTVC.albumMoverClipboard = albumMoverClipboard
		}
		
		super.prepare(for: segue, sender: sender)
	}
	
}
