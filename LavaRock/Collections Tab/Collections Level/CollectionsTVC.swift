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
	var isRenamingCollection = false // If we have to refresh to reflect changes in the Apple Music library, we'll cancel renaming.
	var albumMoverClipboard: AlbumMoverClipboard?
	let newCollectionDetector = MovedAlbumsToNewCollectionDetector()
	var collectionToDeleteBeforeNextRefresh: Collection?
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		if albumMoverClipboard != nil {
			super.viewDidLoad()
			
		} else {
			if AppleMusicLibraryManager.shared.shouldNextMergeBeSynchronous { // This is true if we just got access to the Apple Music library, and therefore we don't want to show an empty table view while we merge from the Apple Music library for the first time. In that case, we need to merge (synchronously) before calling reloadIndexedLibraryItems().
				AppleMusicLibraryManager.shared.setUpLibraryIfAuthorized()
				
				super.viewDidLoad()
				
			} else {
				super.viewDidLoad()
				
				DispatchQueue.main.async {
					AppleMusicLibraryManager.shared.setUpLibraryIfAuthorized() // You need to do this after beginObservingAndGeneratingNotifications(), because it includes merging changes from the Apple Music library, and we need to observe the notification when merging ends.
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
				flexibleSpaceBarButtonItem,
				floatToTopButton
			]
		}
	}
	
	// MARK: Setup Events
	
	@IBAction func unwindToCollectionsFromEmptyCollection(_ unwindSegue: UIStoryboardSegue) {
		if // If we moved all the albums out of a collection. This doesn't conflict with deleting all the albums from a collection.
			let albumsTVC = unwindSegue.source as? AlbumsTVC,
			let collection = albumsTVC.containerOfData as? Collection,
			collection.contents?.count == 0
		{
			collectionToDeleteBeforeNextRefresh = collection
			refreshDataAndViewsWhenVisible()
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if albumMoverClipboard != nil {
		} else {
			if newCollectionDetector.shouldDetectNewCollectionsOnNextViewWillAppear {
				refreshDataAndViewsWhenVisible() // Re-animates adding the collections we made while moving albums, even though we already saw them get added in the "move albums" sheet. Is that bad?
//				reloadIndexedLibraryItems()
//				tableView.reloadData() // Unfortunately, this makes it so that the row we're exiting doesn't start highlighted and unhighlight during the "back" animation, which it ought to.
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
				managedObjectContext.delete(emptyCollection) // Don't remove the empty collection from indexedLibraryItems here. refreshDataAndViews() will remove it and its table view row for us.
				managedObjectContext.tryToSaveSynchronously()
				collectionToDeleteBeforeNextRefresh = nil
			}
		}
		
		super.viewDidAppear(animated)
	}
	
	// MARK: - Events
	
	// In "moving albums" mode, prevent LibraryTVC from changing the toolbar in the storyboard to the playback toolbar.
	override func refreshBarButtons(animated: Bool) {
		if albumMoverClipboard != nil { return }

		super.refreshBarButtons(animated: animated)
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
