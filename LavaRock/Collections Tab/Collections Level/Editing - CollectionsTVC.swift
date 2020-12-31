//
//  Editing - CollectionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData

extension CollectionsTVC {
	
	// MARK: - Renaming Collection
	
	// WARNING: Using VoiceOver, you can rename Collections at any time, not just in editing mode.
	final func renameCollection(at indexPath: IndexPath) {
		guard let collection = indexedLibraryItems[indexPath.row - numberOfRowsAboveIndexedLibraryItems] as? Collection else { return }
		
		isRenamingCollection = true
		let wasRowSelectedBeforeRenaming = tableView.indexPathsForSelectedRows?.contains(indexPath) ?? false
		
		let dialog = UIAlertController(
			title: LocalizedString.renameCollection,
			message: nil,
			preferredStyle: .alert)
		dialog.addTextField(configurationHandler: { textField in
			// UITextInputTraits
			textField.returnKeyType = .done
			textField.autocapitalizationType = .sentences
			textField.autocorrectionType = .yes
			textField.spellCheckingType = .yes
			textField.smartQuotesType = .yes
			textField.smartDashesType = .yes
			
			// UITextField
			textField.text = collection.title
			textField.placeholder = LocalizedString.title
			textField.clearButtonMode = .whileEditing
		} )
		let cancelAction = UIAlertAction(
			title: LocalizedString.cancel,
			style: .cancel,
			handler: { _ in
				self.isRenamingCollection = false
			}
		)
		let doneAction = UIAlertAction(
			title: LocalizedString.done,
			style: .default,
			handler: { _ in
				let rawProposedTitle = dialog.textFields?[0].text
				let newTitle = Collection.validatedTitle(from: rawProposedTitle)
				
				collection.title = newTitle
				self.managedObjectContext.tryToSave()
				
				self.tableView.reloadRows(at: [indexPath], with: .automatic)
				if wasRowSelectedBeforeRenaming {
					self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
				}
				
				self.isRenamingCollection = false
			}
		)
		dialog.addAction(cancelAction)
		dialog.addAction(doneAction)
		dialog.preferredAction = doneAction
		present(dialog, animated: true, completion: nil)
	}
	
}
