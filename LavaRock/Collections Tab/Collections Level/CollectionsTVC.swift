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
	@IBOutlet var optionsButton: UIBarButtonItem!
	static let defaultCollectionTitle = "New Collection"
	
	// Variables
	var isRenamingCollection = false // If we have to refresh to reflect changes in the Apple Music library, and the refresh will change indexedLibraryItems, we'll cancel renaming.
	var albumMoverClipboard: AlbumMoverClipboard?
	let newCollectionDetector = MovedAlbumsToNewCollectionDetector()
	var collectionToDeleteBeforeNextRefresh: Collection?
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		if albumMoverClipboard != nil {
			super.viewDidLoad()
			
		} else {
			if AppleMusicLibraryManager.shared.shouldNextImportBeSynchronous { // This is true if we just got access to the Apple Music library, and therefore we don't want to show an empty table view while we import from the Apple Music library for the first time. In that case, we need to import (synchronously) before calling reloadIndexedLibraryItems().
				AppleMusicLibraryManager.shared.setUpLibraryIfAuthorized()
				PlayerControllerManager.shared.setUpPlayerControllerIfAuthorized()
				
				super.viewDidLoad()
				
			} else {
				super.viewDidLoad()
				
				DispatchQueue.main.async {
					AppleMusicLibraryManager.shared.setUpLibraryIfAuthorized() // You need to do this after beginObservingAndGeneratingNotifications(), because it includes importing changes from the Apple Music library, and we need to observe the notification when importing ends.
					PlayerControllerManager.shared.setUpPlayerControllerIfAuthorized()
				}
			}
		}
	}
	
	// MARK: Setting Up UI
	
	override func setUpUI() {
		if albumMoverClipboard != nil {
		} else {
			navigationItemButtonsNotEditingMode = [optionsButton] // You need to do this before super, because super sets the navigation item buttons.
		}
		
		super.setUpUI()
		
		// As of iOS 14.0 beta 5, cells that use UIListContentConfiguration change their separator insets when entering and exiting editing mode, but with broken timing and no animation.
		// This stops the separator insets from changing.
		tableView.separatorInsetReference = .fromAutomaticInsets
		tableView.separatorInset.left = 0
		
		if let albumMoverClipboard = albumMoverClipboard {
			navigationItem.prompt = albumMoverClipboard.navigationItemPrompt
			navigationItem.rightBarButtonItem = cancelMoveAlbumsButton
			
		} else {
			toolbarButtonsEditingModeOnly = [
				sortButton,
				flexibleSpaceBarButtonItem,
				floatToTopButton,
				flexibleSpaceBarButtonItem,
				sinkToBottomButton
			]
			sortOptions = ["Title"]
		}
	}
	
	// MARK: Setup Events
	
	@IBAction func unwindToCollectionsFromEmptyCollection(_ unwindSegue: UIStoryboardSegue) {
		if // If we moved all the Albums out of a Collection. This doesn't conflict with *deleting* all the Albums from a Collection.
			let albumsTVC = unwindSegue.source as? AlbumsTVC,
			let collection = albumsTVC.containerOfLibraryItems as? Collection,
			collection.contents?.count == 0
		{
			collectionToDeleteBeforeNextRefresh = collection
			
			// Replace this with didSaveChangesFromAppleMusic()?
			refreshToReflectPlaybackState() // So that the "now playing" indicator never momentarily appears on more than one row.
			refreshDataAndViewsWhenVisible()
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if albumMoverClipboard != nil {
		} else {
			if newCollectionDetector.shouldDetectNewCollectionsOnNextViewWillAppear {
				
				// Replace this with didSaveChangesFromAppleMusic()?
				refreshToReflectPlaybackState() // So that the "now playing" indicator never momentarily appears on more than one row.
				refreshDataAndViewsWhenVisible() // Note: This re-animates adding the Collections we made while moving Albums, even though we already saw them get added in the "move Albums" sheet.
				
				newCollectionDetector.shouldDetectNewCollectionsOnNextViewWillAppear = false
			}
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		if let albumMoverClipboard = albumMoverClipboard {
			if albumMoverClipboard.didAlreadyMakeNewCollection {
				deleteEmptyNewCollection()
			}
		} else {
			if let emptyCollection = collectionToDeleteBeforeNextRefresh {
				if let indexOfEmptyCollection = indexedLibraryItems.firstIndex(where: { onscreenCollection in
					onscreenCollection.objectID == emptyCollection.objectID
				}) {
					let indexOfLastOnscreenCollection = indexedLibraryItems.count - 1
					if indexOfEmptyCollection < indexOfLastOnscreenCollection {
						for indexOfCollectionToShiftUpward in indexOfEmptyCollection + 1 ... indexOfLastOnscreenCollection {
							// TO DO: This is fragile, because the property observer on indexedLibraryItems is designed to automatically set the "index" attribute and will override this if we touch it later.
							let collectionToShiftUpward = indexedLibraryItems[indexOfCollectionToShiftUpward] as? Collection
							collectionToShiftUpward?.index -= 1
						}
					}
				}
				managedObjectContext.delete(emptyCollection) // Don't remove the empty Collection from indexedLibraryItems here. refreshDataAndViews() will remove it and its table view row for us.
				managedObjectContext.tryToSaveSynchronously()
				collectionToDeleteBeforeNextRefresh = nil
			}
		}
		
		super.viewDidAppear(animated)
	}
	
	// MARK: - Events
	
	override func setToolbarButtons(animated: Bool) {
		if albumMoverClipboard != nil { return } // In "moving Albums" mode, prevent LibraryTVC from changing the toolbar in the storyboard to the playback toolbar.
		
		super.setToolbarButtons(animated: animated)
	}
	
	// MARK: - Navigation
	
//	@IBSegueAction func showOptions(_ coder: NSCoder) -> UIViewController? {
//		let dismissClosure = { self.dismiss(animated: true, completion: nil) }
//		return UIHostingController(
//			coder: coder,
//			rootView: OptionsView(
//				window: view.window!,
//				dismissModalHostingControllerHostingThisSwiftUIView: dismissClosure
//			)
//		)
//	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if
			segue.identifier == "Drill Down in Library",
			let albumsTVC = segue.destination as? AlbumsTVC
		{
			albumsTVC.albumMoverClipboard = albumMoverClipboard
			albumsTVC.newCollectionDetector = newCollectionDetector
		}
		
		super.prepare(for: segue, sender: sender)
	}
	
}
