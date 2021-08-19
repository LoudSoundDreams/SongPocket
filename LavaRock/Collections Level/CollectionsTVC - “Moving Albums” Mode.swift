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
			let collectionsViewModel = viewModel as? CollectionsViewModel,
			let albumMoverClipboard = albumMoverClipboard,
			!albumMoverClipboard.didAlreadyMakeNewCollection // Without this, if you're fast, you can finish making a new Collection by tapping "Save" in the dialog, and then tap "New Collection" to bring up another dialog before we enter the first Collection you made.
				// You must reset didAlreadyMakeNewCollection = false both during reverting and if we exit the empty new Collection.
		else { return }
		
		albumMoverClipboard.didAlreadyMakeNewCollection = true
		
		let existingCollectionTitles = collectionsViewModel.group.items.compactMap {
			($0 as? Collection)?.title
		}
		let suggestedTitle = albumMoverClipboard.suggestedCollectionTitle(
			notMatching: Set(existingCollectionTitles),
			context: collectionsViewModel.context)
		previewMakeNewCollection(
			suggestedTitle: suggestedTitle)
		presentDialogToMakeNewCollection(
			suggestedTitle: suggestedTitle)
	}
	
	private func previewMakeNewCollection(
		suggestedTitle: String?
	) {
		guard let collectionsViewModel = viewModel as? CollectionsViewModel else { return } // don't continue to presentDialogToMakeNewCollection if this fails
		
		let indexOfNewCollection = AlbumMoverClipboard.indexOfNewCollection
		
		// Make a new data source.
		let newItems = collectionsViewModel.itemsAfterMakingNewCollection( // Since we're in "moving Albums" mode, CollectionsViewModel should do this in a child managed object context.
			suggestedTitle: suggestedTitle,
			indexOfNewCollection: indexOfNewCollection)
		
		// Update the data source and table view.
		let indexPathOfNewCollection = collectionsViewModel.indexPathFor(
			indexOfItemInGroup: indexOfNewCollection,
			indexOfGroup: CollectionsViewModel.indexOfGroup)
		tableView.performBatchUpdates {
			tableView.scrollToRow(
				at: indexPathOfNewCollection,
				at: .top,
				animated: true)
		} completion: { _ in
			self.setItemsAndRefresh(
				newItems: newItems,
				section: indexPathOfNewCollection.section)
		}
	}
	
	// Match presentDialogToRenameCollection and presentDialogToCombineCollections.
	private func presentDialogToMakeNewCollection(
		suggestedTitle: String?
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
				proposedTitle: proposedTitle)
		}
		
		dialog.addAction(cancelAction)
		dialog.addAction(saveAction)
		dialog.preferredAction = saveAction
		
		present(dialog, animated: true)
	}
	
	final func revertMakeNewCollectionIfEmpty() {
		guard
			let albumMoverClipboard = albumMoverClipboard,
			let collectionsViewModel = viewModel as? CollectionsViewModel
		else { return }
		
		albumMoverClipboard.didAlreadyMakeNewCollection = false
		
		let indexOfNewCollection = AlbumMoverClipboard.indexOfNewCollection
		
		// Update the data source and table view.
		let newItems = collectionsViewModel.itemsAfterDeletingCollection(
			indexOfCollection: indexOfNewCollection)
		let indexPathOfDeletedCollection = collectionsViewModel.indexPathFor(
			indexOfItemInGroup: indexOfNewCollection,
			indexOfGroup: CollectionsViewModel.indexOfGroup)
		setItemsAndRefresh(
			newItems: newItems,
			section: indexPathOfDeletedCollection.section)
	}
	
	private func renameAndOpenNewCollection(
		proposedTitle: String?
	) {
		guard let collectionsViewModel = viewModel as? CollectionsViewModel else { return }
		
		let indexOfNewCollection = AlbumMoverClipboard.indexOfNewCollection
		let didChangeTitle = collectionsViewModel.renameCollection(
			proposedTitle: proposedTitle,
			indexOfCollection: indexOfNewCollection)
		
		let indexPathOfNewCollection = collectionsViewModel.indexPathFor(
			indexOfItemInGroup: indexOfNewCollection,
			indexOfGroup: CollectionsViewModel.indexOfGroup)
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
	
}
