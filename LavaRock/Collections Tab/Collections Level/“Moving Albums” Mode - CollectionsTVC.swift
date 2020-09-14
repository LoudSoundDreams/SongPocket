//
//  “Moving Albums” Mode - CollectionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData

extension CollectionsTVC {
	
	// MARK: - Deleting New Collection
	
	func deleteEmptyNewCollection() {
		let indexOfEmptyNewCollection = 0
		
		guard
			let albumMoverClipboard = albumMoverClipboard,
			albumMoverClipboard.didAlreadyMakeNewCollection,
			let collection = indexedLibraryItems[indexOfEmptyNewCollection] as? Collection,
			collection.contents?.count == 0
		else { return }
		
		managedObjectContext.delete(collection)
		indexedLibraryItems.remove(at: indexOfEmptyNewCollection)
		tableView.deleteRows(
			at: [IndexPath(row: indexOfEmptyNewCollection - numberOfRowsAboveIndexedLibraryItems, section: 0)],
			with: .middle)
		
		albumMoverClipboard.didAlreadyMakeNewCollection = false
	}
	
	// MARK: - Making New Collection
	
	@IBAction func presentDialogToMakeNewCollection(_ sender: UIBarButtonItem) {
		guard
			let albumMoverClipboard = albumMoverClipboard,
			!albumMoverClipboard.didAlreadyMakeNewCollection
		else { return } // Without this, if you're fast, you can finish making a new collection by tapping Done in the dialog, and then tap New Collection to bring up another dialog before we enter the first collection you made.
		// Another solution would be to set makeNewCollectionButton.isEnabled = false after tapping Done in the dialog (not before then, in case you tap Cancel in the dialog), and re-enabling it if you back out of the new collection and after we delete that new collection; but it's easier to understand the intention of the didAlreadyMakeNewCollection flag.
		
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
			textField.text = self.suggestedCollectionTitle()
			textField.placeholder = "Title"
			textField.clearButtonMode = .whileEditing
		} )
		dialog.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
			albumMoverClipboard.isMakingNewCollection = false
		}))
		dialog.addAction(UIAlertAction(title: "Done", style: .default, handler: { _ in
			
			albumMoverClipboard.isMakingNewCollection = false
			albumMoverClipboard.didAlreadyMakeNewCollection = true
			
			let indexPathOfNewCollection = IndexPath(row: 0, section: 0)
			
			// Create the new collection.
			
			var newTitle = dialog.textFields?[0].text
			if (newTitle == nil) || (newTitle == "") {
				newTitle = Self.defaultCollectionTitle
			}
			
			let newCollection = Collection(context: self.managedObjectContext) // Since we're in "moving albums" mode, this should be a child managed object context.
			newCollection.title = newTitle
			// The property observer on indexedLibraryItems will set the "index" attribute for us.
			
			self.indexedLibraryItems.insert(newCollection, at: indexPathOfNewCollection.row)
			
			// Enter the new collection.
			
			self.tableView.performBatchUpdates( {
				self.tableView.insertRows(at: [indexPathOfNewCollection], with: .middle)
			}, completion: { _ in
				self.tableView.performBatchUpdates( {
					self.tableView.selectRow(at: indexPathOfNewCollection, animated: true, scrollPosition: .top)
					
				}, completion: { _ in
					self.performSegue(withIdentifier: "Drill Down in Library", sender: indexPathOfNewCollection.row)
				} )
			} )
			
		} ) )
		albumMoverClipboard.isMakingNewCollection = true
		present(dialog, animated: true, completion: nil)
	}
	
	// MARK: Suggesting Collection Title
	
	private func suggestedCollectionTitle() -> String? {
		guard let albumMoverClipboard = albumMoverClipboard else {
			return nil
		}
		
		var existingCollectionTitles = [String]()
		for item in indexedLibraryItems {
			if
				let collection = item as? Collection,
				let collectionTitle = collection.title
			{
				existingCollectionTitles.append(collectionTitle)
			}
		}
		
		return Self.suggestedCollectionTitle(
			for: albumMoverClipboard.idsOfAlbumsBeingMoved,
			in: managedObjectContext,
			notMatching: existingCollectionTitles)
	}
	
	private static func suggestedCollectionTitle(
		for albumIDs: [NSManagedObjectID],
		in managedObjectContext: NSManagedObjectContext,
		notMatching existingCollectionTitles: [String]?
	) -> String? {
		
		for albumProperty in AlbumPropertyToConsider.allCases {
			if let suggestion = suggestedCollectionTitle(
				for: albumIDs,
				in: managedObjectContext,
				notMatching: existingCollectionTitles,
				considering: albumProperty
			) {
				return suggestion
			} else {
				continue
			}
		}
		return nil
	}
	
	private enum AlbumPropertyToConsider: CaseIterable {
		case albumArtist // Order matters. First, we'll see if all the albums have the same artist; if they don't, then we'll try the next case, and so on.
	}
	
	private static func suggestedCollectionTitle(
		for albumIDs: [NSManagedObjectID],
		in managedObjectContext: NSManagedObjectContext,
		notMatching existingCollectionTitles: [String]?,
		considering albumProperty: AlbumPropertyToConsider
	) -> String? {
		if albumIDs.count < 1 {
			return nil
		}
		
		func valueForAlbumProperty(_ albumProperty: AlbumPropertyToConsider, on album: Album) -> String? {
			let representativeItem = album.mpMediaItemCollection()?.representativeItem
			switch albumProperty {
			case .albumArtist:
				return representativeItem?.albumArtist
			}
		}
		
		let firstAlbum = managedObjectContext.object(with: albumIDs[0]) as! Album
		let propertyValueForFirstAlbum = valueForAlbumProperty(albumProperty, on: firstAlbum)
		if
			let existingCollectionTitles = existingCollectionTitles,
			let propertyValueForFirstAlbum = propertyValueForFirstAlbum,
			existingCollectionTitles.contains(propertyValueForFirstAlbum)
		{
			return nil
		}
		
		// Case: 1 album
		if albumIDs.count == 1 {
			return propertyValueForFirstAlbum
			
		} else {
			// Case: 2 or more albums
			let secondAlbum = managedObjectContext.object(with: albumIDs[1]) as! Album
			let propertyValueForSecondAlbum = valueForAlbumProperty(albumProperty, on: secondAlbum)
			
			guard propertyValueForFirstAlbum == propertyValueForSecondAlbum else {
				return nil
			}
			
			if albumIDs.count == 2 {
				// Terminating case.
				return propertyValueForSecondAlbum
				
			} else {
				// Recursive case.
				var albumIDsMutable = albumIDs
				albumIDsMutable.removeFirst()
				
				return suggestedCollectionTitle(
					for: albumIDsMutable,
					in: managedObjectContext,
					notMatching: existingCollectionTitles,
					considering: albumProperty
				)
			}
		}
	}
	
}
