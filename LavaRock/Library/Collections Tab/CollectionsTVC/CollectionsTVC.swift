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
	
	func setSuggestedCollectionTitle(for idsOfAlbumsBeingMoved: [NSManagedObjectID]) {
		var existingCollectionTitles = [String]()
		for item in activeLibraryItems {
			if
				let collection = item as? Collection,
				let collectionTitle = collection.title
			{
				existingCollectionTitles.append(collectionTitle)
			}
		}

		suggestedCollectionTitle = Self.suggestedCollectionTitle(
			for: idsOfAlbumsBeingMoved,
			in: coreDataManager.managedObjectContext,
			considering: ["albumArtist"],
			notMatching: existingCollectionTitles
		)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if newCollectionDetector.shouldDetectNewCollectionsOnNextViewWillAppear {
			loadSavedLibraryItems() // shouldDetectNewCollectionsOnNextViewWillAppear also acts as a flag that tells loadSavedLibraryItems() to not call mergeChangesFromAppleMusicLibrary(), because that deletes empty collections for us. We want to animate that.
			tableView.reloadData() // Unfortunately, this makes it so that the row we're exiting doesn't start highlighted and unhighlight during the "back" animation, which it ought to.
			newCollectionDetector.shouldDetectNewCollectionsOnNextViewWillAppear = false
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
	
	// MARK: Loading Data
	
	override func loadSavedLibraryItems() {
		super.loadSavedLibraryItems()
		
		if moveAlbumsClipboard != nil {
		} else { // Not in "move albums" mode
			if !newCollectionDetector.shouldDetectNewCollectionsOnNextViewWillAppear {
				mergeChangesFromAppleMusicLibrary()
				
				super.loadSavedLibraryItems() // Or rather, the full implementation above; just don't cause an infinite loop calling mergeChangesFromAppleMusicLibrary().
			}
		}
	}
	
	// MARK: Table View
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return super.tableView(tableView, cellForRowAt: indexPath)
		}
		
		// Get the data to put into the cell.
		
		let cellCollection = activeLibraryItems[indexPath.row] as! Collection
		
		// Make, configure, and return the cell.
		
		let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
		
		if #available(iOS 14, *) {
			var configuration = cell.defaultContentConfiguration()
			configuration.text = cellCollection.title
			
			if let moveAlbumsClipboard = moveAlbumsClipboard {
				if cellCollection.objectID == moveAlbumsClipboard.idOfCollectionThatAlbumsAreBeingMovedOutOf {
					configuration.textProperties.color = .placeholderText // A dedicated way to make cells look disabled would be better. This is slightly different from the old cell.textLabel.isEnabled = false.
					cell.selectionStyle = .none
				}
			}

			cell.contentConfiguration = configuration

		} else { // iOS 13 and earlier
			cell.textLabel?.text = cellCollection.title
			
			if let moveAlbumsClipboard = moveAlbumsClipboard {
				if cellCollection.objectID == moveAlbumsClipboard.idOfCollectionThatAlbumsAreBeingMovedOutOf {
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
		
		coreDataManager.managedObjectContext.delete(collection)
		activeLibraryItems.remove(at: index)
		if moveAlbumsClipboard != nil {
		} else {
			coreDataManager.save()
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
	
	// MARK: - “Move Albums" Mode
	
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
			textField.text = self.suggestedCollectionTitle
			textField.placeholder = "Title"
			textField.clearButtonMode = .whileEditing
		} )
		dialog.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		dialog.addAction(UIAlertAction(title: "Done", style: .default, handler: { _ in
			
			let indexPathOfNewCollection = IndexPath(row: 0, section: 0)
			
			// Create the new collection.
			
			var newTitle = dialog.textFields?[0].text
			if (newTitle == nil) || (newTitle == "") {
				newTitle = Self.defaultCollectionTitle
			}
			
			let newCollection = Collection(context: self.coreDataManager.managedObjectContext) // Since we're in "move albums" mode, this should be a child managed object context.
			newCollection.title = newTitle
			
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
	
	// MARK: Events
	
	@IBAction func unwindToCollectionsFromEmptyCollection(_ unwindSegue: UIStoryboardSegue) {
		let albumsTVC = unwindSegue.source as! AlbumsTVC
		let emptyCollection = albumsTVC.containerOfData as! Collection
		indexOfEmptyCollection = Int(emptyCollection.index)
	}
	
	// MARK: - Renaming
	
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
			let collection = self.activeLibraryItems[indexPath.row] as! Collection
			textField.text = collection.title
			textField.placeholder = "Title"
			textField.clearButtonMode = .whileEditing
		} )
		dialog.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		dialog.addAction(UIAlertAction(title: "Done", style: .default, handler: { _ in
			var newTitle = dialog.textFields?[0].text
			if (newTitle == nil) || (newTitle == "") {
				newTitle = Self.defaultCollectionTitle
			}
			
			let collection = self.activeLibraryItems[indexPath.row] as! Collection
			collection.title = newTitle
			self.coreDataManager.save()
			
			self.tableView.reloadRows(at: [indexPath], with: .automatic)
			if wasRowSelectedBeforeRenaming {
				self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
			}
		}) )
		present(dialog, animated: true, completion: nil)
	}
	
}
