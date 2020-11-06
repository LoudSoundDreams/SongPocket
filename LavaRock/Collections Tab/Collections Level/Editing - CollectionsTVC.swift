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
			title: "Rename Collection",
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
			textField.placeholder = "Title"
			textField.clearButtonMode = .whileEditing
		} )
		dialog.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
			self.isRenamingCollection = false
		}))
		dialog.addAction(UIAlertAction(title: "Done", style: .default, handler: { _ in
			var newTitle = dialog.textFields?[0].text
			if (newTitle == nil) || (newTitle == "") {
				newTitle = Self.defaultCollectionTitle
			}
			
			collection.title = newTitle
			self.managedObjectContext.tryToSave()
			
			self.tableView.reloadRows(at: [indexPath], with: .automatic)
			if wasRowSelectedBeforeRenaming {
				self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
			}
			
			self.isRenamingCollection = false
		}) )
		present(dialog, animated: true, completion: nil)
	}
	
}
