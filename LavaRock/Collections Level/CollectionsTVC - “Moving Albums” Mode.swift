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
	
	// MARK: - Making New Collection
	
	final func previewMakeNewCollectionAndPresentDialog() {
		guard
			let albumMoverClipboard = albumMoverClipboard,
			!albumMoverClipboard.didAlreadyMakeNewCollection // Without this, if you're fast, you can finish making a new Collection by tapping "Save" in the dialog, and then tap "New Collection" to bring up another dialog before we enter the first Collection you made.
				// You must reset didAlreadyMakeNewCollection = false both during reverting and if we exit the empty new Collection.
		else { return }
		
		albumMoverClipboard.didAlreadyMakeNewCollection = true
		
		let suggestedTitle = suggestedCollectionTitle()
		previewMakeNewCollection(
			withSuggestedTitle: suggestedTitle)
		presentDialogToMakeNewCollection(
			withSuggestedTitle: suggestedTitle)
	}
	
	private func previewMakeNewCollection(
		withSuggestedTitle suggestedTitle: String?
	) {
		// Create the new Collection.
		let newCollection = Collection(context: context) // Since we're in "moving Albums" mode, this should be a child managed object context.
		newCollection.title = suggestedTitle ?? LocalizedString.newCollectionDefaultTitle
		// When we set sectionOfLibraryItems.items, the property observer will set the "index" attribute of each Collection for us.
		
		let indexOfNewCollection = AlbumMoverClipboard.indexOfNewCollection
		
		// Make a new data source.
		var newItems = sectionOfLibraryItems.items
		newItems.insert(newCollection, at: indexOfNewCollection)
		
		// Update the data source and table view.
		let indexPathOfNewCollection = indexPathFor(
			indexOfLibraryItem: indexOfNewCollection,
			indexOfSectionOfLibraryItem: 0)
		tableView.performBatchUpdates {
			tableView.scrollToRow(
				at: indexPathOfNewCollection,
				at: .top,
				animated: true)
		} completion: { _ in
			self.setItemsAndRefreshToMatch(newItems: newItems)
		}
	}
	
	// Match presentDialogToRenameCollection and presentDialogToCombineCollections.
	private func presentDialogToMakeNewCollection(
		withSuggestedTitle suggestedTitle: String?
	) {
		let dialog = UIAlertController(
			title: LocalizedString.newCollectionAlertTitle,
			message: nil,
			preferredStyle: .alert)
		dialog.addTextFieldForCollectionTitle(defaultTitle: suggestedTitle)
		
		let cancelAction = UIAlertAction.cancel { _ in
			self.revertMakeNewCollectionIfEmpty()
		}
		let saveAction = UIAlertAction(
			title: LocalizedString.save,
			style: .default
		) { _ in
			let proposedTitle = dialog.textFields?[0].text
			self.renameAndOpenNewCollection(
				withProposedTitle: proposedTitle)
		}
		
		dialog.addAction(cancelAction)
		dialog.addAction(saveAction)
		dialog.preferredAction = saveAction
		
		present(dialog, animated: true)
	}
	
	final func revertMakeNewCollectionIfEmpty() {
		let indexOfNewCollection = AlbumMoverClipboard.indexOfNewCollection
		
		guard
			let albumMoverClipboard = albumMoverClipboard,
			let collection = sectionOfLibraryItems.items[indexOfNewCollection] as? Collection,
			collection.isEmpty()
		else { return }
		
		albumMoverClipboard.didAlreadyMakeNewCollection = false
		
		context.delete(collection)
		
		// Update the data source and table view.
		var newItems = sectionOfLibraryItems.items
		newItems.remove(at: indexOfNewCollection)
		setItemsAndRefreshToMatch(newItems: newItems)
	}
	
	private func renameAndOpenNewCollection(
		withProposedTitle proposedTitle: String?
	) {
		let indexOfNewCollection = AlbumMoverClipboard.indexOfNewCollection
		
		guard let newCollection = sectionOfLibraryItems.items[indexOfNewCollection] as? Collection else { return }
		
		let oldTitle = newCollection.title
		if let newTitle = Collection.validatedTitleOptional(from: proposedTitle) {
			newCollection.title = newTitle
		}
		let didChangeTitle = newCollection.title != oldTitle
		
		let indexPathOfNewCollection = indexPathFor(
			indexOfLibraryItem: indexOfNewCollection,
			indexOfSectionOfLibraryItem: 0)
		tableView.performBatchUpdates {
			if didChangeTitle {
				tableView.reloadRows(at: [indexPathOfNewCollection], with: .fade)
			}
		} completion: { _ in
			self.tableView.selectRow(
				at: indexPathOfNewCollection,
				animated: true,
				scrollPosition: .none)
			self.performSegue(
				withIdentifier: "Drill Down in Library",
				sender: nil)
		}
	}
	
	// MARK: Suggesting Title
	
	private func suggestedCollectionTitle() -> String? {
		guard let albumMoverClipboard = albumMoverClipboard else {
			return nil
		}
		
		let albumIDs = albumMoverClipboard.idsOfAlbumsBeingMoved
		let existingCollectionTitles = sectionOfLibraryItems.items.compactMap {
			($0 as? Collection)?.title
		}
		return Self.suggestedCollectionTitle(
			considering: albumIDs,
			notMatching: existingCollectionTitles,
			context: context)
	}
	
	private static func suggestedCollectionTitle(
		considering albumIDs: [NSManagedObjectID],
		notMatching existingCollectionTitles: [String],
		context: NSManagedObjectContext
	) -> String? {
		let albumPropertyKeyPaths = [
			// Order matters. First, we'll see if all the Albums have the same album artist; if they don't, then we'll try the next case, and so on.
			\MPMediaItem.albumArtist
		]
		for albumPropertyKeyPath in albumPropertyKeyPaths {
			if let suggestion = suggestedCollectionTitle(
				considering: albumIDs,
				notMatching: existingCollectionTitles,
				albumPropertyKeyPath: albumPropertyKeyPath,
				context: context
			) {
				return suggestion
			}
		}
		return nil
	}
	
	private static func suggestedCollectionTitle(
		considering albumIDs: [NSManagedObjectID],
		notMatching existingCollectionTitles: [String],
		albumPropertyKeyPath: KeyPath<MPMediaItem, String?>,
		context: NSManagedObjectContext
	) -> String? {
		// If we have no albumIDs, return nil.
		guard
			let firstAlbumID = albumIDs.first,
			let firstAlbum = context.object(with: firstAlbumID) as? Album
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
				considering: restOfAlbumIDs,
				notMatching: existingCollectionTitles,
				albumPropertyKeyPath: albumPropertyKeyPath,
				context: context)
			
			guard metadataValueForFirstAlbum == suggestedCollectionTitleForRestOfAlbums else {
				return nil
			}
			
			return metadataValueForFirstAlbum
		}
	}
	
}
