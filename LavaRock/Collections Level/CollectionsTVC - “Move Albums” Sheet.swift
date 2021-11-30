//
//  CollectionsTVC - “Move Albums” Sheet.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData
import MediaPlayer

extension CollectionsTVC {
	
	final func createAndConfirm() {
		guard
			let collectionsViewModel = viewModel as? CollectionsViewModel,
			case let .movingAlbums(clipboard) = purpose,
			!clipboard.didAlreadyCreate // Without this, if you're fast, you can finish creating a new Collection by tapping "Save" in the dialog, and then tap "New Collection" to bring up another dialog before we enter the first Collection you made.
				// You must reset didAlreadyCreate = false both during reverting and if we exit the empty new Collection.
		else { return }
		
		clipboard.didAlreadyCreate = true
		
		let existingCollectionTitles = collectionsViewModel.group.items.compactMap {
			($0 as? Collection)?.title
		}
		let smartTitle = clipboard.smartCollectionTitle(
			notMatching: Set(existingCollectionTitles),
			context: collectionsViewModel.context)
		create(smartTitle: smartTitle) {
			self.confirmCreate(smartTitle: smartTitle)
		}
	}
	
	private func create(
		smartTitle: String?,
		completion: (() -> Void)?
	) {
		let collectionsViewModel = viewModel as! CollectionsViewModel
		
		let title = smartTitle ?? (FeatureFlag.multicollection ? LocalizedString.newSectionDefaultTitle : LocalizedString.newCollectionDefaultTitle)
		let (newViewModel, indexPathOfNewCollection) = collectionsViewModel.updatedAfterCreating(title: title)
		
		tableView.performBatchUpdates {
			tableView.scrollToRow(
				at: indexPathOfNewCollection,
				at: .none,
				animated: true)
		} completion: { _ in
//			self.setViewModelAndMoveRows(
//				newViewModel,
//				with: .fade)
			self.setViewModelAndMoveRows(newViewModel)
			completion?()
		}
	}
	
	private func confirmCreate(smartTitle: String?) {
		let dialog = UIAlertController.forEditingCollectionTitle(
			alertTitle: FeatureFlag.multicollection ? LocalizedString.newSectionAlertTitle : LocalizedString.newCollectionAlertTitle,
			textFieldText: smartTitle,
			cancelHandler: revertCreate,
			saveHandler: { textFieldText in
				self.renameAndOpenCreated(proposedTitle: textFieldText)
			}
		)
		present(dialog, animated: true)
	}
	
	final func revertCreate() {
		guard
			case let .movingAlbums(clipboard) = purpose,
			let collectionsViewModel = viewModel as? CollectionsViewModel
		else { return }
		
		clipboard.didAlreadyCreate = false
		
		let newViewModel = collectionsViewModel.updatedAfterDeletingNewCollection()
//		setViewModelAndMoveRows(
//			newViewModel,
//			with: .fade)
		setViewModelAndMoveRows(newViewModel)
	}
	
	private func renameAndOpenCreated(proposedTitle: String?) {
		guard let collectionsViewModel = viewModel as? CollectionsViewModel else { return }
		
		let indexPath = collectionsViewModel.indexPathOfNewCollection
		
		let didRename = collectionsViewModel.rename(
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
