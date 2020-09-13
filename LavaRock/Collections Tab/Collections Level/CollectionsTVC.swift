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
	@IBOutlet var makeNewCollectionButton: UIBarButtonItem!
	static let defaultCollectionTitle = "New Collection"
	
	// Variables
	var isRenamingCollection = false // If we have to refresh to reflect changes in the Apple Music library, we'll cancel renaming.
	var albumMoverClipboard: AlbumMoverClipboard?
	let newCollectionDetector = MovedAlbumsToNewCollectionDetector()
	var collectionToDeleteBeforeNextRefresh: Collection?
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		if albumMoverClipboard != nil {
		} else {
			if AppleMusicLibraryManager.shared.shouldNextMergeBeSynchronous { // This is true if we just got access to the Apple Music library, and therefore we don't want to show the user an empty table view while we merge from the Apple Music library for the first time; in that case, we need to merge (synchronously) before calling reloadIndexedLibraryItems() (in super).
				AppleMusicLibraryManager.shared.setUpLibraryIfAuthorized()
			}
		}
		
		super.viewDidLoad()
		
		if albumMoverClipboard != nil {
		} else {
			DispatchQueue.main.async {
				AppleMusicLibraryManager.shared.setUpLibraryIfAuthorized() // You need to do this after beginObservingNotifications() (in super.viewDidLoad()), because it includes merging changes from the Apple Music library, and we need to observe the notification when merging ends.
			}
		}
	}
	
	// MARK: Setting Up UI
	
	override func setUpUI() {
		super.setUpUI()
		
		// As of iOS 14.0 beta 5, cells that use UIListContentConfiguration change their separator insets when entering and exiting editing mode, but with broken timing and no animation.
		// This stops the separator insets from changing.
		tableView.separatorInsetReference = .fromAutomaticInsets
		tableView.separatorInset.left = 0
		
		if let albumMoverClipboard = albumMoverClipboard {
			navigationItem.prompt = albumMoverClipboard.navigationItemPrompt
			navigationItem.rightBarButtonItem = cancelMoveAlbumsButton
			
			navigationController?.isToolbarHidden = false
			
		} else {
			navigationItemButtonsNotEditingMode = [optionsButton]
			
			navigationController?.isToolbarHidden = true
		}
	}
	
	// MARK: Setup Events
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if albumMoverClipboard != nil {
		} else {
			if newCollectionDetector.shouldDetectNewCollectionsOnNextViewWillAppear {
				reloadIndexedLibraryItems()
				tableView.reloadData() // Unfortunately, this makes it so that the row we're exiting doesn't start highlighted and unhighlight during the "back" animation, which it ought to.
				newCollectionDetector.shouldDetectNewCollectionsOnNextViewWillAppear = false
			}
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		if let albumMoverClipboard = albumMoverClipboard {
			if albumMoverClipboard.didAlreadyMakeNewCollection {
				deleteCollectionIfEmpty(withIndex: 0)
			}
		} else {
			if let emptyCollection = collectionToDeleteBeforeNextRefresh {
				managedObjectContext.delete(emptyCollection) // For each collection below the empty collection, we'll need to subtract 1 from its index to shift it upward to close the gap. But that'll happen automatically during the refresh.
				managedObjectContext.tryToSaveSynchronously()
				collectionToDeleteBeforeNextRefresh = nil
			}
		}
		
		super.viewDidAppear(animated)
	}
	
	@IBAction func unwindToCollectionsFromEmptyCollection(_ unwindSegue: UIStoryboardSegue) {
		if // If we moved all the albums out of a collection.
			let albumsTVC = unwindSegue.source as? AlbumsTVC,
			let collection = albumsTVC.containerOfData as? Collection,
			collection.contents?.count == 0
		{
			collectionToDeleteBeforeNextRefresh = collection
			refreshDataAndViewsWhenVisible()
		}
	}
	
	// MARK: - Events
	
	private func deleteCollectionIfEmpty(withIndex indexOfCollection: Int) {
		guard
			let collection = indexedLibraryItems[indexOfCollection] as? Collection,
			collection.contents?.count == 0
		else { return }
		
		managedObjectContext.delete(collection)
		indexedLibraryItems.remove(at: indexOfCollection)
		if albumMoverClipboard != nil {
		} else {
			managedObjectContext.tryToSave()
		}
		tableView.deleteRows(
			at: [IndexPath(row: indexOfCollection - numberOfRowsAboveIndexedLibraryItems, section: 0)],
			with: .middle)
		
		if let albumMoverClipboard = albumMoverClipboard {
			albumMoverClipboard.didAlreadyMakeNewCollection = false
		}
	}
	
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
