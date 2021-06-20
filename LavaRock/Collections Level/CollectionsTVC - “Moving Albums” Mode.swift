//
//  CollectionsTVC - “Moving Albums” Mode.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData
import MediaPlayer

extension CollectionsTVC {
	
	// MARK: - Deleting New Collection
	
	final func deleteEmptyNewCollection() {
		let indexOfEmptyNewCollection = 0
		
		guard
			let albumMoverClipboard = albumMoverClipboard,
			albumMoverClipboard.didAlreadyMakeNewCollection,
			let collection = sectionOfLibraryItems.items[indexOfEmptyNewCollection] as? Collection,
			collection.isEmpty()
		else { return }
		
		managedObjectContext.delete(collection)
		
		var newItems = sectionOfLibraryItems.items
		newItems.remove(at: indexOfEmptyNewCollection)
		setItemsAndRefreshTableView(
			newItems: newItems,
			completion: nil)
		
		albumMoverClipboard.didAlreadyMakeNewCollection = false
	}
	
	// MARK: - Making New Collection
	
	// Match renameCollection(at:).
	@objc final func presentDialogToMakeNewCollection() {
		guard
			let albumMoverClipboard = albumMoverClipboard,
			!albumMoverClipboard.didAlreadyMakeNewCollection
		else { return } // Without this, if you're fast, you can finish making a new Collection by tapping Done in the dialog, and then tap New Collection to bring up another dialog before we enter the first Collection you made.
		
		let dialog = UIAlertController(
			title: LocalizedString.titleForAlertNewCollection,
			message: nil,
			preferredStyle: .alert)
		dialog.addTextField(configurationHandler: { textField in
			// UITextField
			textField.text = self.suggestedCollectionTitle()
			textField.placeholder = LocalizedString.title
			textField.clearButtonMode = .whileEditing
			
			// UITextInputTraits
			textField.returnKeyType = .done
			textField.autocapitalizationType = .sentences
			textField.smartQuotesType = .yes
			textField.smartDashesType = .yes
		})
		let cancelAction = UIAlertAction(
			title: LocalizedString.cancel,
			style: .cancel,
			handler: nil)
		let saveAction = UIAlertAction(
			title: LocalizedString.save,
			style: .default,
			handler: { [self] _ in
				albumMoverClipboard.didAlreadyMakeNewCollection = true
				
				let indexOfNewCollection = 0
				
				// Create the new Collection.
				
				let rawProposedTitle = dialog.textFields?[0].text
				let newTitle = Collection.validatedTitle(from: rawProposedTitle)
				
				let newCollection = Collection(context: managedObjectContext) // Since we're in "moving Albums" mode, this should be a child managed object context.
				newCollection.title = newTitle
				// When we set sectionOfLibraryItems.items, the property observer will set the "index" attribute of each Collection for us.
				
				var newItems = sectionOfLibraryItems.items
				newItems.insert(newCollection, at: indexOfNewCollection)
				setItemsAndRefreshTableView(
					newItems: newItems,
					completion: {
						let indexPath = indexPathFor(
							indexOfLibraryItem: indexOfNewCollection,
							indexOfSectionOfLibraryItem: 0)
						tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
						performSegue(
							withIdentifier: "Drill Down in Library",
							sender: nil)
					})
			}
		)
		dialog.addAction(cancelAction)
		dialog.addAction(saveAction)
		dialog.preferredAction = saveAction
		present(dialog, animated: true)
	}
	
	// MARK: Suggesting Title
	
	private func suggestedCollectionTitle() -> String? {
		guard let albumMoverClipboard = albumMoverClipboard else {
			return nil
		}
		
		let existingCollectionTitles = sectionOfLibraryItems.items.compactMap {
			($0 as? Collection)?.title
		}
		return Self.suggestedCollectionTitle(
			for: albumMoverClipboard.idsOfAlbumsBeingMoved,
			in: managedObjectContext,
			notMatching: existingCollectionTitles)
	}
	
	private static func suggestedCollectionTitle(
		for albumIDs: [NSManagedObjectID],
		in managedObjectContext: NSManagedObjectContext,
		notMatching existingCollectionTitles: [String]
	) -> String? {
		let albumPropertyKeyPaths = [
			// Order matters. First, we'll see if all the Albums have the same album artist; if they don't, then we'll try the next case, and so on.
			\MPMediaItem.albumArtist
		]
		for albumPropertyKeyPath in albumPropertyKeyPaths {
			if let suggestion = suggestedCollectionTitle(
				for: albumIDs,
				in: managedObjectContext,
				considering: albumPropertyKeyPath,
				notMatching: existingCollectionTitles
			) {
				return suggestion
			}
		}
		return nil
	}
	
	private static func suggestedCollectionTitle(
		for albumIDs: [NSManagedObjectID],
		in managedObjectContext: NSManagedObjectContext,
		considering albumPropertyKeyPath: KeyPath<MPMediaItem, String?>,
		notMatching existingCollectionTitles: [String]
	) -> String? {
		// If we have no albumIDs, return nil.
		guard
			let firstAlbumID = albumIDs.first,
			let firstAlbum = managedObjectContext.object(with: firstAlbumID) as? Album
		else {
			return nil
		}
		
		// If we can't fetch any metadata for the first album, return nil.
		guard let metadataValueForFirstAlbum = firstAlbum.mpMediaItemCollection()?.representativeItem?[keyPath: albumPropertyKeyPath] else {
			return nil
		}
		
		if albumIDs.count == 1 {
			// If the metadata for the first album matches an existing title, return nil.
			guard !existingCollectionTitles.contains(metadataValueForFirstAlbum) else {
				return nil
			}
			return metadataValueForFirstAlbum
		} else {
			// 2 or more Albums
			let restOfAlbumIDs = Array(albumIDs.dropFirst())
			let suggestedCollectionTitleForRestOfAlbums = suggestedCollectionTitle(
				for: restOfAlbumIDs,
				in: managedObjectContext,
				considering: albumPropertyKeyPath,
				notMatching: existingCollectionTitles)
			
			guard metadataValueForFirstAlbum == suggestedCollectionTitleForRestOfAlbums else {
				return nil
			}
			
			return metadataValueForFirstAlbum
		}
	}
	
}
