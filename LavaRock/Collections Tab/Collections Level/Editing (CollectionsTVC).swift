//
//  Editing (CollectionsTVC).swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData

extension CollectionsTVC {
	
	// MARK: - Renaming
	
	func renameCollection(at indexPath: IndexPath) {
		let wasRowSelectedBeforeRenaming = tableView.indexPathsForSelectedRows?.contains(indexPath) ?? false
		let dialog = UIAlertController(title: "Rename Collection", message: nil, preferredStyle: .alert)
		dialog.addTextField(configurationHandler: { textField in
			// UITextInputTraits
			textField.returnKeyType = .done
			textField.autocapitalizationType = .sentences
			textField.autocorrectionType = .yes
			textField.spellCheckingType = .yes
			textField.smartQuotesType = .yes
			textField.smartDashesType = .yes
			
			// UITextField
//			guard let collection = self.fetchedResultsController?.object(at: indexPath) as? Collection else {
//				return
//			}
			let collection = self.indexedLibraryItems[indexPath.row - self.numberOfRowsAboveIndexedLibraryItems] as! Collection
			textField.text = collection.title
			textField.placeholder = "Title"
			textField.clearButtonMode = .whileEditing
		} )
		dialog.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		dialog.addAction(UIAlertAction(title: "Done", style: .default, handler: { _ in
			var newTitle = dialog.textFields?[0].text
			if (newTitle == nil) || (newTitle == "") {
				newTitle = Self.defaultCollectionTitle
			}
			
//			guard let collection = self.fetchedResultsController?.object(at: indexPath) as? Collection else {
//				return
//			}
			let collection = self.indexedLibraryItems[indexPath.row - self.numberOfRowsAboveIndexedLibraryItems] as! Collection
			collection.title = newTitle
			self.managedObjectContext.tryToSave()
			
			self.tableView.reloadRows(at: [indexPath], with: .automatic)
			if wasRowSelectedBeforeRenaming {
				self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
			}
		}) )
		present(dialog, animated: true, completion: nil)
	}
	
}
