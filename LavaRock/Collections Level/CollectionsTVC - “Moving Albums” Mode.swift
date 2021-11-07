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
	
	private func previewMakeNewCollection(suggestedTitle: String?) {
		guard let collectionsViewModel = viewModel as? CollectionsViewModel else { return } // TO DO: Don't continue to presentDialogToMakeNewCollection if this fails
		
		// Make a new data source.
		let (newViewModel, indexPathOfNewCollection) = collectionsViewModel.updatedAfterCreatingNewCollectionInOnlyGroup(
			suggestedTitle: suggestedTitle)
		
		// Update the data source and table view.
		tableView.performBatchUpdates {
			tableView.scrollToRow(
				at: indexPathOfNewCollection,
				at: .top,
				animated: true)
		} completion: { _ in
			self.setViewModelAndMoveRows(newViewModel)
		}
	}
	
	// Match presentDialogToRenameCollection and presentDialogToCombineCollections.
	private func presentDialogToMakeNewCollection(suggestedTitle: String?) {
		let dialog = UIAlertController(
			title: LocalizedString.newCollectionAlertTitle,
			message: nil,
			preferredStyle: .alert)
		dialog.addTextFieldForCollectionTitle(defaultTitle: suggestedTitle)
		
		let cancelAction = UIAlertAction.cancel { _ in
			self.revertMakeNewCollection()
		}
		let saveAction = UIAlertAction(
			title: LocalizedString.save,
			style: .default
		) { _ in
			let proposedTitle = dialog.textFields?.first?.text
			self.renameAndOpenNewCollection(
				proposedTitle: proposedTitle)
		}
		
		dialog.addAction(cancelAction)
		dialog.addAction(saveAction)
		dialog.preferredAction = saveAction
		
		present(dialog, animated: true)
	}
	
	final func revertMakeNewCollection() {
		guard
			let albumMoverClipboard = albumMoverClipboard,
			let collectionsViewModel = viewModel as? CollectionsViewModel
		else { return }
		
		albumMoverClipboard.didAlreadyMakeNewCollection = false
		
		// Make a new data source.
		let newViewModel = collectionsViewModel.updatedAfterDeletingNewCollection()
		
		// Update the data source and table view.
		setViewModelAndMoveRows(newViewModel)
	}
	
	private func renameAndOpenNewCollection(proposedTitle: String?) {
		guard let collectionsViewModel = viewModel as? CollectionsViewModel else { return }
		
		let indexPath = collectionsViewModel.indexPathOfNewCollection
		
		let didChangeTitle = collectionsViewModel.rename(
			at: indexPath,
			proposedTitle: proposedTitle)
		
		tableView.performBatchUpdates {
			if didChangeTitle {
				tableView.reloadRows(at: [indexPath], with: .fade)
			}
		} completion: { _ in
			self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
			self.performSegue(withIdentifier: "Open Collection", sender: self)
		}
	}
	
}
