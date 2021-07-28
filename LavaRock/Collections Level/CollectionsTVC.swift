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
		case justFinishedLoading
		case normal
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
	var didJustFinishLoading = false
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
		if didJustFinishLoading { // You must check didJustFinishLoading before checking isImportingChanges.
			return .justFinishedLoading
		}
		if
			isImportingChanges,
			sectionOfLibraryItems.isEmpty()
		{
			return .loading
		}
		return .normal
	}
	
	final func deleteAllRowsIfFinishedLoading() {
		if contentState() == .loading {
			didJustFinishLoading = true // contentState() is now .justFinishedLoading
			refreshToReflectContentState()
			didJustFinishLoading = false
		}
	}
	
	private func refreshToReflectContentState(
		completion: (() -> ())? = nil
	) {
		let oldIndexPaths = tableView.allIndexPaths()
		switch contentState() {
		case .allowAccess /*Currently unused*/, .loading:
			let indexPathsToKeep = [IndexPath(row: 0, section: 0)]
			let updateTableView: () -> () = {
				switch oldIndexPaths.count {
				case 0: // Launch -> "Loading…"
					return {
						self.tableView.insertRows(at: indexPathsToKeep, with: .fade)
					}
				case 1: // "Allow Access" -> "Loading…"
					return {
						self.tableView.reloadRows(at: indexPathsToKeep, with: .fade)
					}
				default: // Currently unused
					let indexPathsToDelete = Array(oldIndexPaths.dropFirst())
					return {
						self.tableView.deleteRows(at: indexPathsToDelete, with: .fade)
						self.tableView.reloadRows(at: indexPathsToKeep, with: .fade)
					}
				}
			}()
			tableView.performBatchUpdates {
				updateTableView()
			} completion: { _ in
				completion?()
			}
		case .justFinishedLoading: // "Loading…" -> empty
			tableView.performBatchUpdates {
				tableView.deleteRows(at: oldIndexPaths, with: .middle)
			} completion: { _ in
				completion?()
			}
		case .normal: // Importing changes with existing Collections
			completion?()
		}
	}
	
	// MARK: - Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		sortOptionGroups = [
			[.title],
			[.reverse]
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
		
		isImportingChanges = true // contentState() is now .loading or .normal (updating)
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
