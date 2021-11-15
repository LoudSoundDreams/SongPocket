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
	
	final func previewCreateCollectionAndPresentDialog() {
		guard
			let collectionsViewModel = viewModel as? CollectionsViewModel,
			let albumMoverClipboard = albumMoverClipboard,
			!albumMoverClipboard.didAlreadyCreateCollection // Without this, if you're fast, you can finish making a new Collection by tapping "Save" in the dialog, and then tap "New Collection" to bring up another dialog before we enter the first Collection you made.
				// You must reset didAlreadyCreateCollection = false both during reverting and if we exit the empty new Collection.
		else { return }
		
		albumMoverClipboard.didAlreadyCreateCollection = true
		
		let existingCollectionTitles = collectionsViewModel.group.items.compactMap {
			($0 as? Collection)?.title
		}
		let smartTitle = albumMoverClipboard.smartCollectionTitle(
			notMatching: Set(existingCollectionTitles),
			context: collectionsViewModel.context)
		previewCreateCollection(smartTitle: smartTitle) {
			self.presentDialogToCreateCollection(smartTitle: smartTitle)
		}
	}
	
	private func previewCreateCollection(
		smartTitle: String?,
		completion: (() -> Void)?
	) {
		guard let collectionsViewModel = viewModel as? CollectionsViewModel else { return }
		
		let (newViewModel, indexPathOfNewCollection) = collectionsViewModel.updatedAfterCreatingCollectionInOnlyGroup(
			smartTitle: smartTitle)
		
		tableView.performBatchUpdates {
			tableView.scrollToRow(
				at: indexPathOfNewCollection,
				at: .none,
				animated: true)
		} completion: { _ in
			self.setViewModelAndMoveRows(newViewModel) {
				completion?()
			}
		}
	}
	
	// Match presentDialogToRenameCollection and presentDialogToCombineCollections.
	private func presentDialogToCreateCollection(smartTitle: String?) {
		let dialog = UIAlertController(
			title: FeatureFlag.multicollection ? LocalizedString.newSectionAlertTitle : LocalizedString.newCollectionAlertTitle,
			message: nil,
			preferredStyle: .alert)
		dialog.addTextFieldForRenamingCollection(withText: smartTitle)
		
		let cancelAction = UIAlertAction.cancel { _ in
			self.revertCreateCollection()
		}
		let saveAction = UIAlertAction(
			title: LocalizedString.save,
			style: .default
		) { _ in
			let proposedTitle = dialog.textFields?.first?.text
			self.renameAndOpenNewCollection(proposedTitle: proposedTitle)
		}
		
		dialog.addAction(cancelAction)
		dialog.addAction(saveAction)
		dialog.preferredAction = saveAction
		
		present(dialog, animated: true)
	}
	
	final func revertCreateCollection() {
		guard
			let albumMoverClipboard = albumMoverClipboard,
			let collectionsViewModel = viewModel as? CollectionsViewModel
		else { return }
		
		albumMoverClipboard.didAlreadyCreateCollection = false
		
		let newViewModel = collectionsViewModel.updatedAfterDeletingNewCollection()
		
		setViewModelAndMoveRows(newViewModel)
	}
	
	private func renameAndOpenNewCollection(proposedTitle: String?) {
		guard let collectionsViewModel = viewModel as? CollectionsViewModel else { return }
		
		let indexPath = collectionsViewModel.indexPathOfNewCollection
		
		let didRename = collectionsViewModel.didRename(
			at: indexPath,
			proposedTitle: proposedTitle)
		
		tableView.performBatchUpdates {
			if didRename {
				tableView.reloadRows(at: [indexPath], with: .fade)
			}
		} completion: { _ in
			self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
			self.performSegue(withIdentifier: "Open Collection", sender: self)
		}
	}
	
}
