//
//  CollectionsTVC - “Move Albums” Sheet.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData

@MainActor
extension CollectionsTVC {
	private static func smartCollectionTitle(
		moving albumsOutOfOrder: [Album]
	) -> String? {
		guard let someAlbum = albumsOutOfOrder.first else {
			return nil
		}
		let otherAlbums = albumsOutOfOrder.dropFirst()
		// Don't query for all the album artists upfront, because that's slow.
		
		let existingTitles: Set<String>? = {
			guard let context = someAlbum.managedObjectContext else {
				return nil
			}
			let allCollections = Collection.allFetched(ordered: false, via: context)
			return Set(allCollections.compactMap { $0.title })
		}()
		
		// Check whether the album artists of the albums we're moving are all identical.
	albumArtistIdentical: do {
		let someAlbumArtist = someAlbum.albumArtistFormattedOrPlaceholder()
		
		if
			let existingTitles = existingTitles,
			existingTitles.contains(someAlbumArtist)
		{
			break albumArtistIdentical
		}
		
		if otherAlbums.allSatisfy({
			$0.albumArtistFormattedOrPlaceholder() == someAlbumArtist
		}) {
			return someAlbumArtist
		}
	}
		
		// Otherwise, give up.
		return nil
	}
	
	final func createAndPrompt() {
		guard
			case let .movingAlbums(clipboard) = purpose,
			!clipboard.didAlreadyCreate, // Without this, if you’re fast, you can tap “Save” to create a new `Collection`, then tap “New Collection” to bring up another dialog before we open the first `Collection` you made. You must reset `didAlreadyCreate = false` both during reverting and if we exit the empty new `Collection`.
			let collectionsViewModel = viewModel as? CollectionsViewModel
		else { return }
		
		clipboard.didAlreadyCreate = true
		
		let smartTitle: String? = {
			let albumsBeingMoved = clipboard.idsOfAlbumsBeingMoved.compactMap {
				viewModel.context.object(with: $0) as? Album
			}
			return Self.smartCollectionTitle(moving: albumsBeingMoved)
		}()
		
		let title = smartTitle ?? (
			Enabling.multicollection
			? LocalizedString.newSectionDefaultTitle
			: LocalizedString.newCollectionDefaultTitle)
		let newViewModel = collectionsViewModel.updatedAfterCreating(title: title)
		Task {
			await setViewModelAndMoveRows_async(newViewModel)
			
			let dialog = UIAlertController.forEditingCollectionTitle(
				alertTitle: Enabling.multicollection ? LocalizedString.newSectionAlertTitle : LocalizedString.newCollectionAlertTitle,
				textFieldText: smartTitle,
				textFieldDelegate: self,
				cancelHandler: {
					self.revertCreate()
				},
				saveHandler: { textFieldText in
					self.renameAndOpenCreated(proposedTitle: textFieldText)
				})
			present(dialog, animated: true)
		}
	}
	
	final func revertCreate() {
		guard
			case let .movingAlbums(clipboard) = purpose,
			let collectionsViewModel = viewModel as? CollectionsViewModel
		else { return }
		
		clipboard.didAlreadyCreate = false
		
		let newViewModel = collectionsViewModel.updatedAfterDeletingNewCollection()
		setViewModelAndMoveRows(newViewModel)
	}
	
	private func renameAndOpenCreated(proposedTitle: String?) {
		guard let collectionsViewModel = viewModel as? CollectionsViewModel else { return }
		
		let indexPath = collectionsViewModel.indexPathOfNewCollection
		
		let didChangeTitle = collectionsViewModel.renameAndReturnDidChangeTitle(
			at: indexPath,
			proposedTitle: proposedTitle)
		
		Task {
			let _ = await tableView.performBatchUpdates_async {
				guard didChangeTitle else { return }
				self.tableView.reloadRows(at: [indexPath], with: .fade)
			}
			
			tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
			performSegue(withIdentifier: "Open Collection", sender: self)
		}
	}
}
