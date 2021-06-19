//
//  CollectionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-05-04.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import CoreData
//import SwiftUI
import MediaPlayer

final class CollectionsTVC:
	LibraryTVC,
	AlbumMover
{
	
	// MARK: - Properties
	
	// "Constants"
	@IBOutlet private var optionsButton: UIBarButtonItem!
	private lazy var makeNewCollectionButton = UIBarButtonItem(
		barButtonSystemItem: .add,
		target: self,
		action: #selector(presentDialogToMakeNewCollection))
	
	// Variables
	var isLoading: Bool {
		return
			isImportingChanges &&
			sectionOfLibraryItems.items.isEmpty &&
			MPMediaLibrary.authorizationStatus() == .authorized
	}
	var didJustFinishLoading = false
	var albumMoverClipboard: AlbumMoverClipboard?
	var didMoveAlbums = false
	
	// MARK: - Setup
	
	final override func viewDidLoad() {
		super.viewDidLoad()
		
		if albumMoverClipboard != nil {
		} else {
			if MPMediaLibrary.authorizationStatus() == .authorized {
				DispatchQueue.main.async { // Show existing Collections as soon as possible, then integrate with the built-in Music app shortly later.
					self.isImportingChanges = true
					// contentState() is now .loading
					self.refreshToReflectContentState(completion: {
						self.integrateWithBuiltInMusicApp()
					})
//					else if isUpdating {
//						refreshAndSetBarButtons(animated: false)
//						DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) { // Wait for the Edit button to actually change into the spinner before continuing
//							integrateWithBuiltInMusicApp()
//						}
//					}
				}
			}
		}
	}
	
	// Similar to viewDidLoad().
	final func didReceiveAuthorizationForMusicLibrary() {
		setUp()
		
		isImportingChanges = true
		// contentState() is now .loading
		refreshToReflectContentState(completion: {
			self.integrateWithBuiltInMusicApp()
		})
	}
	
	// Call this method late into launch, after we've already set up most of the UI; this method sets up the MediaPlayer-related functionality so that we can set up the rest of the UI (although this method itself doesn't set up the rest of the UI).
	// Before calling this, put the UI into the "Loading…" or "Updating…" state.
	private func integrateWithBuiltInMusicApp() {
		MusicLibraryManager.shared.setUpLibraryAndImportChanges() // During a typical launch, we need to observe the notification after the import completes, so only do this after LibraryTVC's beginObservingNotifications(). After we observe that notification, we refresh our data and views, including the playback toolbar.
		PlayerManager.setUp() // This actually doesn't trigger refreshing the playback toolbar; refreshing after importing changes (above) does.
	}
	
	// MARK: Setting Up UI
	
	final override func setUpUI() {
		// Choose our buttons for the navigation bar and toolbar before calling super, because super sets those buttons.
		if albumMoverClipboard != nil {
//			topLeftButtonsInViewingMode = [cancelMoveAlbumsButton]
//			topRightButtons = [makeNewCollectionButton]
//			navigationController?.toolbar.isHidden = true
			
			topLeftButtonsInViewingMode = []
			topRightButtons = [cancelMoveAlbumsButton]
			bottomButtonsInViewingMode = [
				.flexibleSpac3(),
				makeNewCollectionButton,
				.flexibleSpac3(),
			]
		} else {
			topLeftButtonsInViewingMode = [optionsButton]
		}
		
		super.setUpUI()
		
		// As of iOS 14.0 beta 5, cells that use UIListContentConfiguration change their separator insets when entering and exiting editing mode, but with broken timing and no animation.
		// This stops the separator insets from changing.
		tableView.separatorInsetReference = .fromAutomaticInsets
		tableView.separatorInset.left = 0
		
		if let albumMoverClipboard = albumMoverClipboard {
			navigationItem.prompt = albumMoverClipboard.navigationItemPrompt
			
		} else {
			bottomButtonsInEditingMode = [
				sortButton,
				.flexibleSpac3(),
				floatToTopButton,
				.flexibleSpac3(),
				sinkToBottomButton,
			]
			sortOptions = [
				.title,
				.reverse,
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
				refreshToReflectPlaybackState() // So that the "now playing" indicator never momentarily appears on more than one row.
				refreshDataAndViewsWhenVisible() // Note: This re-animates adding the Collections we made while moving Albums, even though we already saw them get added in the "move Albums" sheet.
				
				didMoveAlbums = false
			}
		}
	}
	
	final override func viewDidAppear(_ animated: Bool) {
		if let albumMoverClipboard = albumMoverClipboard {
			if albumMoverClipboard.didAlreadyMakeNewCollection {
				deleteEmptyNewCollection()
			}
		}
		
		super.viewDidAppear(animated)
	}
	
	// MARK: - Navigation
	
//	@IBSegueAction func showOptions(_ coder: NSCoder) -> UIViewController? {
//		return UIHostingController(
//			coder: coder,
//			rootView: OptionsView(
//				window: view.window!
//			)
//		)
//	}
	
	final override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if
			segue.identifier == "Drill Down in Library",
			let albumsTVC = segue.destination as? AlbumsTVC
		{
			albumsTVC.albumMoverClipboard = albumMoverClipboard
		}
		
		super.prepare(for: segue, sender: sender)
	}
	
}
