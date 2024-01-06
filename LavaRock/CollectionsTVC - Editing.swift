//
//  CollectionsTVC - Editing.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData

extension CollectionsTVC: UITextFieldDelegate {
	func textFieldDidBeginEditing(_ textField: UITextField) {
		textField.selectAll(nil) // As of iOS 15.3 developer beta 1, the selection works but the highlight doesn’t appear if `textField.text` is long.
	}
}
extension CollectionsTVC {
	
	// MARK: Rename
	
	func promptRename(at indexPath: IndexPath) {
		guard let collection = viewModel.itemNonNil(atRow: indexPath.row) as? Collection else { return }
		
		let dialog = UIAlertController(
			title: LRString.rename,
			message: nil,
			preferredStyle: .alert)
		
		dialog.addTextField {
			// UITextField
			$0.text = collection.title
			$0.placeholder = LRString.tilde
			$0.clearButtonMode = .always
			
			// UITextInputTraits
			$0.returnKeyType = .done
			$0.autocapitalizationType = .sentences
			$0.smartQuotesType = .yes
			$0.smartDashesType = .yes
			
			$0.delegate = self
		}
		
		dialog.addAction(UIAlertAction(title: LRString.cancel, style: .cancel))
		
		let rowWasSelectedBeforeRenaming = tableView.selectedIndexPaths.contains(indexPath)
		let done = UIAlertAction(title: LRString.done, style: .default) { [weak self] _ in
			self?.commitRename(
				textFieldText: dialog.textFields?.first?.text,
				indexPath: indexPath,
				thenShouldReselect: rowWasSelectedBeforeRenaming
			)
		}
		dialog.addAction(done)
		dialog.preferredAction = done
		
		present(dialog, animated: true)
	}
	private func commitRename(
		textFieldText: String?,
		indexPath: IndexPath,
		thenShouldReselect: Bool
	) {
		let collectionsViewModel = viewModel as! CollectionsViewModel
		let collection = collectionsViewModel.collectionNonNil(atRow: indexPath.row)
		
		let proposedTitle = (textFieldText ?? "").truncated(toMaxLength: 256) // In case the user entered a dangerous amount of text
		if proposedTitle.isEmpty {
			collection.title = LRString.tilde
		} else {
			collection.title = proposedTitle
		}
		
		tableView.performBatchUpdates {
			tableView.reloadRows(at: [indexPath], with: .fade)
		}
		if thenShouldReselect {
			tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
		}
	}
}
