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

final class CollectionsTVC: LibraryTableViewController {
	
	@IBOutlet var optionsButton: UIBarButtonItem!
	static let defaultCollectionTitle = "Unnamed Collection"
	var indexOfEmptyCollection: Int?
	
	// "Move albums" mode
	var suggestedCollectionTitle: String?
	
	// MARK: Setting Up UI
	
	override func viewDidLoad() {
		navigationItem.leftBarButtonItems = nil // Removes Options button added in the storyboard. We'll re-add it in code.
		navigationItemButtonsNotEditMode = [optionsButton]
		
		super.viewDidLoad()
		
		if collectionsNC.isInMoveAlbumsMode {
			DispatchQueue.global(qos: .userInitiated).async {
				self.setSuggestedCollectionTitle()
			}
		}
	}
	
	func setSuggestedCollectionTitle() {
		var existingCollectionTitles = [String]()
		for item in self.activeLibraryItems {
			if
				let collection = item as? Collection,
				let collectionTitle = collection.title
			{
				existingCollectionTitles.append(collectionTitle)
			}
		}
		
		self.suggestedCollectionTitle = Self.suggestedCollectionTitle(
			for: self.collectionsNC.managedObjectIDsOfAlbumsBeingMoved,
			in: self.collectionsNC.coreDataManager.managedObjectContext,
			considering: ["albumArtist"],
			notMatching: existingCollectionTitles
		)
	}
	
	// MARK: Loading Data
	
	override func loadActiveLibraryItems() {
		super.loadActiveLibraryItems()
		
		if !collectionsNC.isInMoveAlbumsMode {
			if activeLibraryItems.isEmpty {
				// Just for testing.
				SampleLibrary.inject()
				super.loadActiveLibraryItems()
			}
			
			
//			SampleLibrary.setThumbnailsInBackground(activeLibraryItems as! [Collection])
			
			
		}
	}
	
	// MARK: Events
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if collectionsNC.didMoveAlbumsToNewCollections {
			loadActiveLibraryItems()
			tableView.reloadData() // Unfortunately, this makes it so that the row we're exiting doesn't start highlighted and unhighlight during the "back" animation, which it ought to.
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if collectionsNC.isInMoveAlbumsMode {
			deleteCollectionIfEmpty(at: 0)
			
		} else {
			if indexOfEmptyCollection != nil {
				deleteCollectionIfEmpty(at: indexOfEmptyCollection!)
				indexOfEmptyCollection = nil
			}
			
		}
	}
	
	func deleteCollectionIfEmpty(at index: Int) {
		guard let collection = activeLibraryItems[index] as? Collection,
			collection.contents?.count == 0 else {
				return
		}
		
		collectionsNC.coreDataManager.managedObjectContext.delete(collection)
		activeLibraryItems.remove(at: index)
		if !collectionsNC.isInMoveAlbumsMode {
			collectionsNC.coreDataManager.save()
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
	
	// MARK: “Move Albums" Mode
	
	@IBAction func makeNewCollection(_ sender: UIBarButtonItem) {
		let dialog = UIAlertController(title: "New Collection", message: nil, preferredStyle: .alert)
		dialog.addTextField(configurationHandler: { textField in
			// UITextInputTraits
			textField.returnKeyType = .done
			textField.autocapitalizationType = .sentences
			textField.autocorrectionType = .yes
			textField.spellCheckingType = .yes
			textField.smartQuotesType = .yes
			textField.smartDashesType = .yes
			
			// UITextField
			textField.text = self.suggestedCollectionTitle ?? Self.defaultCollectionTitle
			textField.placeholder = "Title"
			textField.clearButtonMode = .whileEditing
		} )
		dialog.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		dialog.addAction(UIAlertAction(title: "Done", style: .default, handler: { _ in
			
			let indexPathOfNewCollection = IndexPath(row: 0, section: 0)
			
			// Create the new collection.
			let newCollection = Collection(context: self.collectionsNC.coreDataManager.managedObjectContext) // Since we're in "move albums mode", this should be a child managed object context.
			var newCollectionTitle = dialog.textFields?[0].text
			if (newCollectionTitle == nil) || (newCollectionTitle == "") {
				newCollectionTitle = Self.defaultCollectionTitle
			}
			newCollection.title = newCollectionTitle
			self.activeLibraryItems.insert(newCollection, at: indexPathOfNewCollection.row)
			
			// Enter the new collection.
			self.tableView.performBatchUpdates( {
				self.tableView.insertRows(at: [indexPathOfNewCollection], with: .middle)
				
			}, completion: { _ in
				self.tableView.performBatchUpdates( {
					self.tableView.selectRow(at: indexPathOfNewCollection, animated: true, scrollPosition: .top) // The entire app crashes if you try to complete scrolling before insertRows.
					
				}, completion: { _ in
					self.performSegue(withIdentifier: "Drill Down in Library", sender: indexPathOfNewCollection.row)
				} )
			} )
			
		} ) )
		present(dialog, animated: true, completion: nil)
	}
	
	private static func suggestedCollectionTitle(
		for albumIDs: [NSManagedObjectID],
		in managedObjectContext: NSManagedObjectContext,
		considering attributeNamesRanked: [String], // For example, ["albumArtist", "composer", "genre"]
		notMatching existingCollectionTitles: [String]?
	) -> String? {
		if attributeNamesRanked.count < 1 {
			return nil
		}
		
		// Try the first attribute.
		if let firstSuggestion = suggestedCollectionTitle(
			for: albumIDs,
			in: managedObjectContext,
			considering: attributeNamesRanked.first!,
			notMatching: existingCollectionTitles
		) {
			return firstSuggestion
			
		} else {
			// Try the next attribute.
			var attributeNamesRankedMutable = attributeNamesRanked
			attributeNamesRankedMutable.removeFirst()
			
			return suggestedCollectionTitle(
				for: albumIDs,
				in: managedObjectContext,
				considering: attributeNamesRankedMutable,
				notMatching: existingCollectionTitles
			)
		}
	}
	
	private static func suggestedCollectionTitle(
		for albumIDs: [NSManagedObjectID],
		in managedObjectContext: NSManagedObjectContext,
		considering attributeName: String,
		notMatching existingCollectionTitles: [String]?
	) -> String? {
		if albumIDs.count < 1 {
			return nil
		}
		
		let firstAlbum = managedObjectContext.object(with: albumIDs[0])
		let attributeValueForFirstAlbum = firstAlbum.value(forKey: attributeName) as? String
		if
			let existingCollectionTitles = existingCollectionTitles,
			let attributeValueForFirstAlbum = attributeValueForFirstAlbum,
			existingCollectionTitles.contains(attributeValueForFirstAlbum)
		{
			return nil
		}
		
		// Case: 1 album
		if albumIDs.count == 1 {
			return attributeValueForFirstAlbum
			
		} else {
			// Case: 2 or more albums
			let secondAlbum = managedObjectContext.object(with: albumIDs[1])
			let attributeValueForSecondAlbum = secondAlbum.value(forKey: attributeName) as? String
			
			guard attributeValueForFirstAlbum == attributeValueForSecondAlbum else {
				return nil
			}
			
			if albumIDs.count == 2 {
				// Terminating case.
				return attributeValueForSecondAlbum
				
			} else {
				// Recursive case.
				var albumIDsMutable = albumIDs
				albumIDsMutable.removeFirst()
				
				return suggestedCollectionTitle(
					for: albumIDsMutable,
					in: managedObjectContext,
					considering: attributeName,
					notMatching: existingCollectionTitles
				)
			}
		}
	}
	
	// Ending moving albums
	
	@IBAction func unwindToCollectionsFromEmptyCollection(_ unwindSegue: UIStoryboardSegue) {
		let sourceViewController = unwindSegue.source as! AlbumsTVC
		let emptyCollection = sourceViewController.containerOfData as! Collection
		indexOfEmptyCollection = Int(emptyCollection.index)
	}
	
	// MARK: Renaming
	
	override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
		renameCollection(at: indexPath)
	}
	
	func renameCollection(at indexPath: IndexPath) {
		let wasRowSelectedBeforeRenaming = tableView.indexPathsForSelectedRows?.contains(indexPath) ?? false
		let dialog = UIAlertController(title: "Rename Collection", message: nil, preferredStyle: .alert)
		dialog.addTextField(configurationHandler: { textField in
			// UITextInputTraits
			textField.returnKeyType = .done
			textField.autocapitalizationType = .sentences
			textField.autocorrectionType = .yes
			textField.spellCheckingType = .yes
			textField.smartQuotesType = .yes
			textField.smartDashesType = .yes
			
			// UITextField
			textField.text = self.activeLibraryItems[indexPath.row].value(forKey: "title") as? String
			textField.placeholder = "Title"
			textField.clearButtonMode = .whileEditing
		} )
		dialog.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		dialog.addAction(UIAlertAction(title: "Done", style: .default, handler: { action in
			var newTitle = dialog.textFields?[0].text
			if (newTitle == nil) || (newTitle == "") {
				newTitle = Self.defaultCollectionTitle
			}
			
			self.activeLibraryItems[indexPath.row].setValue(newTitle, forKey: "title")
			self.tableView.reloadRows(at: [indexPath], with: .fade)
			if wasRowSelectedBeforeRenaming {
				self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
			}
			self.collectionsNC.coreDataManager.save()
		}) )
		present(dialog, animated: true, completion: nil)
	}
	
}
