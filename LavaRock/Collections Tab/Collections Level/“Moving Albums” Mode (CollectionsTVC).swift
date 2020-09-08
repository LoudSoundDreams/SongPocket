//
//  “Moving Albums” Mode (CollectionsTVC).swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData

extension CollectionsTVC {
	
	func setSuggestedCollectionTitle(for idsOfAlbumsBeingMoved: [NSManagedObjectID]) {
		var existingCollectionTitles = [String]()
		for item in indexedLibraryItems {
			if
				let collection = item as? Collection,
				let collectionTitle = collection.title
			{
				existingCollectionTitles.append(collectionTitle)
			}
		}
		
		suggestedCollectionTitle = Self.suggestedCollectionTitle(
			for: idsOfAlbumsBeingMoved,
			in: managedObjectContext,
			notMatching: existingCollectionTitles
		)
	}
	
	@IBAction func makeNewCollection(_ sender: UIBarButtonItem) {
		guard !didAlreadyMakeNewCollection else { return } // Without this, if you're fast, you can finish making a new collection by tapping Done in the dialog, and then tap New Collection to bring up another dialog before we enter the first collection you made.
		// Another solution would be to disable the "make new collection" button after tapping Done in the dialog (not before then, in case you tap Cancel in the dialog), and re-enabling it if you back out of the new collection, after we delete that new collection; but it's easier to understand the intention of the didAlreadyMakeNewCollection flag.
		
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
			
			self.didAlreadyMakeNewCollection = true
			
			// In viewWillAppear, we enable the button, in case you exit the new collection you made, because then we delete it and you should be able to make another one.
			
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
					self.tableView.selectRow(at: indexPathOfNewCollection, animated: true, scrollPosition: .top) // The entire app crashes if you try to complete scrolling before insertRows.
					
				}, completion: { _ in
					self.performSegue(withIdentifier: "Drill Down in Library", sender: indexPathOfNewCollection.row)
				} )
			} )
			
		} ) )
		present(dialog, animated: true, completion: nil)
	}
	
	private enum AlbumPropertyToConsider {
		case albumArtist
	}
	
	private static let rankedAlbumPropertiesToConsiderWhenSuggestingCollectionTitle: [AlbumPropertyToConsider] = [.albumArtist]
	
	private static func suggestedCollectionTitle(
		for albumIDs: [NSManagedObjectID],
		in managedObjectContext: NSManagedObjectContext,
		notMatching existingCollectionTitles: [String]?
	) -> String? {
		for albumProperty in Self.rankedAlbumPropertiesToConsiderWhenSuggestingCollectionTitle {
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
