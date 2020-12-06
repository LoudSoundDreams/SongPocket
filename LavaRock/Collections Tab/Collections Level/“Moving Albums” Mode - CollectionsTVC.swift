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
	
	final func deleteEmptyNewCollection() {
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
		else { return } // Without this, if you're fast, you can finish making a new Collection by tapping Done in the dialog, and then tap New Collection to bring up another dialog before we enter the first Collection you made.
		
		let dialog = UIAlertController(
			title: LocalizedString.newCollection,
			message: nil,
			preferredStyle: .alert)
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
			textField.placeholder = LocalizedString.title
			textField.clearButtonMode = .whileEditing
		} )
		dialog.addAction(UIAlertAction(title: LocalizedString.cancel, style: .cancel, handler: { _ in
			albumMoverClipboard.isMakingNewCollection = false
		}))
		dialog.addAction(UIAlertAction(title: LocalizedString.done, style: .default, handler: { _ in
			
			albumMoverClipboard.isMakingNewCollection = false
			albumMoverClipboard.didAlreadyMakeNewCollection = true
			
			let indexPathOfNewCollection = IndexPath(row: 0, section: 0)
			
			// Create the new Collection.
			
			var newTitle = dialog.textFields?[0].text
			if (newTitle == nil) || (newTitle == "") {
				newTitle = Self.defaultCollectionTitle
			}
			
			let newCollection = Collection(context: self.managedObjectContext) // Since we're in "moving Albums" mode, this should be a child managed object context.
			newCollection.title = newTitle
			// The property observer on indexedLibraryItems will set the "index" attribute for us.
			
			self.indexedLibraryItems.insert(newCollection, at: indexPathOfNewCollection.row)
			
			// Enter the new Collection.
			
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
		case albumArtist // Order matters. First, we'll see if all the Albums have the same album artist; if they don't, then we'll try the next case, and so on.
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
		
		// Case: 1 Album
		if albumIDs.count == 1 {
			return propertyValueForFirstAlbum
			
		} else {
			// Case: 2 or more Albums
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
