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

final class CollectionsTVC: LibraryTVC, AlbumMover {
	
	// MARK: Properties
	
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
			navigationItemButtonsNotEditMode = [optionsButton]
		}
		
		super.viewDidLoad()
		
		if let moveAlbumsClipboard = moveAlbumsClipboard {
			DispatchQueue.global(qos: .userInitiated).async {
				self.setSuggestedCollectionTitle(for: moveAlbumsClipboard.idsOfAlbumsBeingMoved)
			}
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
	
	// MARK: Loading Data
	
	override func loadSavedLibraryItems() {
		super.loadSavedLibraryItems()
		
		if moveAlbumsClipboard != nil {
		} else { // Not in "moving albums" mode
			if !newCollectionDetector.shouldDetectNewCollectionsOnNextViewWillAppear {
				mergeChangesFromAppleMusicLibrary()
				super.loadSavedLibraryItems()
			}
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return super.tableView(tableView, cellForRowAt: indexPath)
		}
		
		// Get the data to put into the cell.
		
		let collection = activeLibraryItems[indexPath.row] as! Collection
		
		// Make, configure, and return the cell.
		
		let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
		
		if #available(iOS 14, *) {
			var configuration = cell.defaultContentConfiguration()
			configuration.text = collection.title
			
			if let moveAlbumsClipboard = moveAlbumsClipboard {
				if collection.objectID == moveAlbumsClipboard.idOfCollectionThatAlbumsAreBeingMovedOutOf {
					configuration.textProperties.color = .placeholderText // A dedicated way to make cells look disabled would be better. This is slightly different from the old cell.textLabel.isEnabled = false.
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
//		let dismissClosure = { self.dismiss(animated: true, completion: nil) } // Does this cause a strong reference cycle?
//		return UIHostingController(
//			coder: coder,
//			rootView: OptionsView(
//				window: view.window!,
//				dismissModalHostingControllerHostingThisSwiftUIView: dismissClosure
//			)
//		)
//	}
	
	override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
		if let moveAlbumsClipboard = moveAlbumsClipboard {
			let collectionID = activeLibraryItems[indexPath.row].objectID
			if collectionID == moveAlbumsClipboard.idOfCollectionThatAlbumsAreBeingMovedOutOf {
				return nil
				
			} else {
				return indexPath
			}
			
		} else {
			return indexPath
		}
	}
	
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
