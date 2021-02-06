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
	
	// Variables
	var isLoading: Bool {
		isEitherLoadingOrUpdating &&
			indexedLibraryItems.isEmpty &&
			MPMediaLibrary.authorizationStatus() == .authorized
	}
	var didJustFinishLoading = false
	var isRenamingCollection = false // If we have to refresh to reflect changes in the Music library, and the refresh will change indexedLibraryItems, we'll cancel renaming.
	var albumMoverClipboard: AlbumMoverClipboard?
	let newCollectionDetector = MovedAlbumsToNewCollectionDetector()
	var collectionToDeleteBeforeNextRefresh: Collection?
	
	// MARK: - Setup
	
	final override func viewDidLoad() {
		super.viewDidLoad()
		
		if albumMoverClipboard != nil {
		} else {
			if MPMediaLibrary.authorizationStatus() == .authorized {
				DispatchQueue.main.async { [self] in // Yes, it's actually useful to use async on the main thread. This lets us show existing collections as soon as possible, then integrate with and import changes from the Music library shortly later.
					isEitherLoadingOrUpdating = true
					tableView.performBatchUpdates {
						if isLoading {
							let indexPath = IndexPath(row: 0, section: 0)
							tableView.insertRows(at: [indexPath], with: .fade)
						}
					} completion: { _ in
						integrateWithAndImportChangesFromMusicLibraryIfAuthorized()
					}
//					else if isUpdating {
//						refreshAndSetBarButtons(animated: false)
//						DispatchQueue.main.asyncAfter(deadline: .now() + 0.03, execute: { // Wait for the Edit button to actually change into the spinner before continuing
//							integrateWithAndImportChangesFromMusicLibraryIfAuthorized()
//						})
//					}
				}
			}
		}
	}
	
	// MARK: Setting Up UI
	
	final override func setUpUI() {
		if albumMoverClipboard != nil {
		} else {
			navigationItemLeftButtonsNotEditingMode = [optionsButton] // You need to do this before super, because super sets the navigation item buttons.
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
			sortOptions = [.title]
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
			
			// Replace this with refreshToReflectMusicLibrary()?
			refreshToReflectPlaybackState() // So that the "now playing" indicator never momentarily appears on more than one row.
			refreshDataAndViewsWhenVisible()
		}
	}
	
	final override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if albumMoverClipboard != nil {
		} else {
			if newCollectionDetector.shouldDetectNewCollectionsOnNextViewWillAppear {
				
				// Replace this with refreshToReflectMusicLibrary()?
				refreshToReflectPlaybackState() // So that the "now playing" indicator never momentarily appears on more than one row.
				refreshDataAndViewsWhenVisible() // Note: This re-animates adding the Collections we made while moving Albums, even though we already saw them get added in the "move Albums" sheet.
				
				newCollectionDetector.shouldDetectNewCollectionsOnNextViewWillAppear = false
			}
		}
	}
	
	final override func viewDidAppear(_ animated: Bool) {
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
	
	final override func setToolbarButtons(animated: Bool) {
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
	
	final override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
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
