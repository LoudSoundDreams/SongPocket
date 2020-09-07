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
	var suggestedCollectionTitle: String?
	static let defaultCollectionTitle = "New Collection"
	
	// Variables
	var moveAlbumsClipboard: AlbumMoverClipboard?
	var shouldRespondToNextMOCDidMergeChangesNotification = false
	let newCollectionDetector = MovedAlbumsToNewCollectionDetector()
	var indexOfEmptyCollection: Int?
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// As of iOS 14.0 beta 5, cells that use UIListContentConfiguration indent their separators in Edit mode, but with broken timing and no animation.
		// This stops the separator insets from changing.
		tableView.separatorInsetReference = .fromAutomaticInsets
		tableView.separatorInset.left = 0
		
		if let moveAlbumsClipboard = moveAlbumsClipboard {
			DispatchQueue.global(qos: .userInitiated).async {
				self.setSuggestedCollectionTitle(for: moveAlbumsClipboard.idsOfAlbumsBeingMoved) // You need to do this after reloadIndexedLibraryItems, because it checks the existing collection titles.
			}
		} else {
//			DispatchQueue.global(qos: .userInteractive).async { // This speeds up launch time significantly, but first, we need to get merging to actually happen concurrently; otherwise, we have a thread issue.
				self.mediaPlayerManager.setUpLibraryIfAuthorized() // This is the starting point for setting up Apple Music library integration.
				// You need to do this after beginObservingNotifications() (in super.viewDidLoad()), because it includes merging changes from the Apple Music library, and we need to observe the notification when merging ends.
//			}
			
//			navigationItemButtonsNotEditMode = [optionsButton]
		}
	}
	
	// MARK: Setting Up UI
	
	override func setUpUI() {
		super.setUpUI()
		
		if let moveAlbumsClipboard = moveAlbumsClipboard {
			navigationItem.prompt = moveAlbumsClipboard.navigationItemPrompt
			navigationItem.rightBarButtonItem = cancelMoveAlbumsButton
			
			navigationController?.isToolbarHidden = false
			
		} else {
			navigationItemButtonsNotEditMode = [optionsButton]
			
			navigationController?.isToolbarHidden = true
		}
	}
	
	// MARK: Setup Events
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if moveAlbumsClipboard != nil {
			makeNewCollectionButton.isEnabled = true
			
		} else {
			if newCollectionDetector.shouldDetectNewCollectionsOnNextViewWillAppear {
				reloadIndexedLibraryItems() // shouldDetectNewCollectionsOnNextViewWillAppear also acts as a flag that tells reloadIndexedLibraryItems() to not call mergeChangesFromAppleMusicLibrary(), because that deletes empty collections for us. We want to animate that.
				tableView.reloadData() // Unfortunately, this makes it so that the row we're exiting doesn't start highlighted and unhighlight during the "back" animation, which it ought to.
				newCollectionDetector.shouldDetectNewCollectionsOnNextViewWillAppear = false
			}
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if moveAlbumsClipboard != nil {
			deleteCollectionIfEmpty(withIndex: 0)
			
		} else {
			if indexOfEmptyCollection != nil {
				deleteCollectionIfEmpty(withIndex: indexOfEmptyCollection!)
				indexOfEmptyCollection = nil
			}
			
		}
	}
	
	@IBAction func unwindToCollectionsAfterMovingAllAlbumsOut(_ unwindSegue: UIStoryboardSegue) {
		let albumsTVC = unwindSegue.source as! AlbumsTVC
		let emptyCollection = albumsTVC.containerOfData as! Collection
		indexOfEmptyCollection = Int(emptyCollection.index)
	}
	
	@IBAction func unwindToCollectionsFromEmptyCollection(_ unwindSegue: UIStoryboardSegue) {
	}
	
	// MARK: - Events
	
	func deleteCollectionIfEmpty(withIndex indexOfCollection: Int) {
		guard
			let collection = indexedLibraryItems[indexOfCollection] as? Collection,
			collection.contents?.count == 0
		else { return }
		
		managedObjectContext.delete(collection)
		indexedLibraryItems.remove(at: indexOfCollection)
		if moveAlbumsClipboard != nil {
		} else {
			managedObjectContext.tryToSave()
		}
		tableView.deleteRows(
			at: [IndexPath(row: indexOfCollection - numberOfRowsAboveIndexedLibraryItems, section: 0)],
			with: .middle)
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
			albumsTVC.moveAlbumsClipboard = moveAlbumsClipboard
			albumsTVC.newCollectionDetector = newCollectionDetector
		}
		
		super.prepare(for: segue, sender: sender)
	}
	
}
