//
//  CollectionsTVC - “Move Albums” Sheet.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit

extension CollectionsTVC {
	private static func suggestedCollectionTitle(
		movingAlbumsInAnyOrder albumsInAnyOrder: [Album]
	) -> String? {
		guard let someAlbum = albumsInAnyOrder.first else {
			return nil
		}
		let otherAlbums = albumsInAnyOrder.dropFirst()
		// Don’t query for all the album artists upfront, because that’s slow.
		
		let existingTitles: Set<String>? = {
			guard let context = someAlbum.managedObjectContext else {
				return nil
			}
			let allCollections = Collection.allFetched(ordered: false, via: context)
			return Set(allCollections.compactMap { $0.title })
		}()
		
		// Check whether the album artists of the albums we’re moving are all identical.
	albumArtistIdentical: do {
		let someAlbumArtist = someAlbum.representativeAlbumArtistFormattedOrPlaceholder()
		
		if
			let existingTitles = existingTitles,
			existingTitles.contains(someAlbumArtist)
		{
			break albumArtistIdentical
		}
		
		if otherAlbums.allSatisfy({
			$0.representativeAlbumArtistFormattedOrPlaceholder() == someAlbumArtist
		}) {
			return someAlbumArtist
		}
	}
		
		// Otherwise, give up.
		return nil
	}
	
	func createAndPrompt() {
		guard
			case let .movingAlbums(clipboard) = purpose,
			!clipboard.didAlreadyCreate, // Without this, if you’re fast, you can tap “Save” to create a new `Collection`, then tap “New Collection” to bring up another dialog before we open the first `Collection` you made. You must reset `didAlreadyCreate = false` both during reverting and if we exit the empty new `Collection`.
			let collectionsViewModel = viewModel as? CollectionsViewModel
		else { return }
		
		clipboard.didAlreadyCreate = true
		
		let titleForNewCollection: String = {
			let albumsBeingMoved = clipboard.idsOfAlbumsBeingMovedAsSet.compactMap {
				viewModel.context.object(with: $0) as? Album
			}
			let suggestedTitle = Self.suggestedCollectionTitle(movingAlbumsInAnyOrder: albumsBeingMoved)
			return suggestedTitle ?? LRString.newCollection_defaultTitle
		}()
		let newViewModel = collectionsViewModel.updatedAfterCreating(title: titleForNewCollection)
		Task {
			guard await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel) else { return }
			
			let dialog = UIAlertController.forEditingCollectionTitle(
				alertTitle: LRString.newCollection_alertTitle,
				textFieldText: titleForNewCollection,
				textFieldDelegate: self,
				cancelHandler: { [weak self] in
					self?.revertCreate()
				},
				saveHandler: { [weak self] textFieldText in
					self?.renameAndOpenCreated(proposedTitle: textFieldText)
				})
			present(dialog, animated: true)
		}
	}
	
	func revertCreate() {
		guard case let .movingAlbums(clipboard) = purpose else {
			fatalError()
		}
		
		let collectionsViewModel = viewModel as! CollectionsViewModel
		
		clipboard.didAlreadyCreate = false
		
		let newViewModel = collectionsViewModel.updatedAfterDeletingNewCollection()
		Task {
			let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel)
		}
	}
	
	private func renameAndOpenCreated(proposedTitle: String?) {
		let collectionsViewModel = viewModel as! CollectionsViewModel
		
		let indexPath = collectionsViewModel.indexPathOfNewCollection
		
		let didChangeTitle = collectionsViewModel.renameAndReturnDidChangeTitle(
			at: indexPath,
			proposedTitle: proposedTitle)
		
		Task {
			if didChangeTitle {
				let _ = await tableView.update__async {
					self.tableView.reloadRows(at: [indexPath], with: .fade)
				}
			}
			
			tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
			performSegue(withIdentifier: "Open Collection", sender: self)
		}
	}
}
