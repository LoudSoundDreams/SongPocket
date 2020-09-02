//
//  CollectionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-05-04.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import CoreData
import SwiftUI
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
	var moveAlbumsClipboard: MoveAlbumsClipboard?
	let newCollectionDetector = MovedAlbumsToNewCollectionDetector()
	var indexOfEmptyCollection: Int?
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		if moveAlbumsClipboard != nil {
		} else {
			mediaPlayerManager.setUpLibraryIfAuthorized() // This is the starting point for setting up Apple Music library integration.
			// This needs to happen before loadSavedLibraryItems, because it includes merging changes from the Apple Music library.
		}
		
		super.viewDidLoad()
		
		// As of iOS 14.0 beta 5, cells that use UIListContentConfiguration indent their separators in Edit mode, but with broken timing and no animation.
		// This stops the separator insets from changing.
		tableView.separatorInsetReference = .fromAutomaticInsets
		tableView.separatorInset.left = 0
		
		if let moveAlbumsClipboard = moveAlbumsClipboard {
			DispatchQueue.global(qos: .userInitiated).async {
				self.setSuggestedCollectionTitle(for: moveAlbumsClipboard.idsOfAlbumsBeingMoved) // This needs to happen after loadSavedLibraryItems, because it checks the existing collection titles.
			}
		} else {
			navigationItemButtonsNotEditMode = [optionsButton]
		}
	}
	
	override func setUpUI() {
		super.setUpUI()
		
		if let moveAlbumsClipboard = moveAlbumsClipboard {
			navigationItem.prompt = MoveAlbumsClipboard.moveAlbumsModePrompt(numberOfAlbumsBeingMoved: moveAlbumsClipboard.idsOfAlbumsBeingMoved.count)
			navigationItem.rightBarButtonItem = cancelMoveAlbumsButton
			
			navigationController?.isToolbarHidden = false
			
		} else {
			navigationController?.isToolbarHidden = true
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if moveAlbumsClipboard != nil {
			makeNewCollectionButton.isEnabled = true
			
		} else {
			if newCollectionDetector.shouldDetectNewCollectionsOnNextViewWillAppear {
				loadSavedLibraryItems() // shouldDetectNewCollectionsOnNextViewWillAppear also acts as a flag that tells loadSavedLibraryItems() to not call mergeChangesFromAppleMusicLibrary(), because that deletes empty collections for us. We want to animate that.
				tableView.reloadData() // Unfortunately, this makes it so that the row we're exiting doesn't start highlighted and unhighlight during the "back" animation, which it ought to.
				newCollectionDetector.shouldDetectNewCollectionsOnNextViewWillAppear = false
			}
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if moveAlbumsClipboard != nil {
			deleteCollectionIfEmpty(at: 0)
			
		} else {
			if indexOfEmptyCollection != nil {
				deleteCollectionIfEmpty(at: indexOfEmptyCollection!)
				indexOfEmptyCollection = nil
			}
			
		}
	}
	
	@IBAction func unwindToCollectionsFromEmptyCollection(_ unwindSegue: UIStoryboardSegue) {
		let albumsTVC = unwindSegue.source as! AlbumsTVC
		let emptyCollection = albumsTVC.containerOfData as! Collection
		indexOfEmptyCollection = Int(emptyCollection.index)
	}
	
	// MARK: - Table View
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return super.tableView(tableView, cellForRowAt: indexPath)
		}
		
		// Get the data to put into the cell.
//		guard let collection = fetchedResultsController?.object(at: indexPath) as? Collection else {
//			return UITableViewCell()
//		}
		let collection = activeLibraryItems[indexPath.row] as! Collection
		
//		print("According to our records, the collection “\(collection.title)” should be at row index \(collection.index); we're making a cell for it at row index \(indexPath.row)")
		
		// Make, configure, and return the cell.
		let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
		if #available(iOS 14, *) {
			var configuration = cell.defaultContentConfiguration()
			configuration.text = collection.title
			
			if let moveAlbumsClipboard = moveAlbumsClipboard {
				if collection.objectID == moveAlbumsClipboard.idOfCollectionThatAlbumsAreBeingMovedOutOf {
					configuration.textProperties.color = .placeholderText // A proper way to make cells look disabled would be better. This is slightly different from the old cell.textLabel.isEnabled = false.
					// TO DO: Tell VoiceOver that this cell is disabled.
					cell.selectionStyle = .none
				}
			}
			
			cell.contentConfiguration = configuration
			
		} else { // iOS 13 and earlier
			cell.textLabel?.text = collection.title
			
			if let moveAlbumsClipboard = moveAlbumsClipboard {
				if collection.objectID == moveAlbumsClipboard.idOfCollectionThatAlbumsAreBeingMovedOutOf {
					cell.textLabel?.isEnabled = false
					cell.selectionStyle = .none
				}
			}
		}
		return cell
	}
	
	// MARK: - Events
	
	override func managedObjectContextDidSave(_ notification: Notification) {
		guard shouldRespondToNextManagedObjectContextDidSaveNotification else { return }
		shouldRespondToNextManagedObjectContextDidSaveNotification = false
		
		let changeTypes = [NSUpdatedObjectsKey, NSInsertedObjectsKey, NSDeletedObjectsKey]
		for changeType in changeTypes {
			if let updatedObjects = notification.userInfo?[changeType] as? Set<NSManagedObject> {
				var updatedCollections = [Collection]()
				for object in updatedObjects {
					if let collection = object as? Collection {
						updatedCollections.append(collection)
						print("The collection “\(String(describing: collection.title))” should be updated with change type “\(changeType)” at index \(collection.index).")
					}
				}
				print("We need to update \(updatedCollections.count) collections with change type “\(changeType)”.")
			}
		}
	}
	
	
	
	func deleteCollectionIfEmpty(at index: Int) {
		guard
			let collection = activeLibraryItems[index] as? Collection,
			collection.contents?.count == 0
		else { return }
		
		managedObjectContext.delete(collection)
		activeLibraryItems.remove(at: index)
		if moveAlbumsClipboard != nil {
		} else {
			managedObjectContext.tryToSave()
		}
		tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .middle)
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
