//
//  CollectionsTVC - Editing.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData

extension CollectionsTVC {
	
//	override func setEditing(_ editing: Bool, animated: Bool) {
//		super.setEditing(
//			editing,
//			animated: animated)
//
//		refreshVoiceControlNamesForAllCells()
//	}
	
//	private func refreshVoiceControlNamesForAllCells() {
//		for indexPath in tableView.indexPathsForRows(
//			inSection: 0,
//			firstRow: numberOfRowsAboveLibraryItems)
//		{
//			guard let cell = tableView.cellForRow(at: indexPath) else { continue }
//			
//			refreshVoiceControlNames(for: cell)
//		}
//	}
	
	// MARK: - Allowing
	
	final func allowsCombine() -> Bool {
		guard !sectionOfLibraryItems.items.isEmpty else {
			return false
		}
		
		return tableView.indexPathsForSelectedRowsNonNil.count >= 2
	}
	
	// MARK: - Renaming
	
	// Match presentDialogToMakeNewCollection.
	final func presentDialogToRenameCollection(at indexPath: IndexPath) {
		guard let collection = libraryItem(for: indexPath) as? Collection else { return }
		
		let wasRowSelectedBeforeRenaming = tableView.indexPathsForSelectedRowsNonNil.contains(indexPath)
		
		let dialog = UIAlertController(
			title: LocalizedString.renameCollection,
			message: nil,
			preferredStyle: .alert)
		dialog.addTextFieldForCollectionTitle(defaultTitle: collection.title)
		
		let cancelAction = UIAlertAction.cancel(handler: nil)
		let saveAction = UIAlertAction(
			title: LocalizedString.save,
			style: .default
		) { _ in
			let proposedTitle = dialog.textFields?[0].text
			self.rename(
				collection,
				withProposedTitle: proposedTitle,
				at: indexPath,
				thenSelectRow: wasRowSelectedBeforeRenaming)
		}
		
		dialog.addAction(cancelAction)
		dialog.addAction(saveAction)
		dialog.preferredAction = saveAction
		
		present(dialog, animated: true)
	}
	
	private func rename(
		_ collection: Collection,
		withProposedTitle proposedTitle: String?,
		at indexPath: IndexPath,
		thenSelectRow: Bool
	) {
		let newTitle = Collection.validatedTitle(from: proposedTitle)
		
		collection.title = newTitle
		managedObjectContext.tryToSave()
		
		tableView.reloadRows(at: [indexPath], with: .fade)
		if thenSelectRow {
			tableView.selectRow(
				at: indexPath,
				animated: false,
				scrollPosition: .none)
		}
	}
	
	// MARK: - Combining
	
	@objc final func presentDialogToCombineSelectedCollections() {
		// Save the previous SectionOfCollectionsOrAlbums for if we need to revert.
//		previousSectionOfCollections = sectionOfLibraryItems
		
		
		let dialog = UIAlertController(
			title: "Combine Collections", // TO DO: Localize
			message: nil,
			preferredStyle: .alert)
		dialog.addTextFieldForCollectionTitle(defaultTitle: nil) //
		
		let cancelAction = UIAlertAction.cancel { _ in
			self.cancelCombineCollections()
		}
		let saveAction = UIAlertAction(
			title: LocalizedString.save,
			style: .default
		) { _ in
			let proposedTitle = dialog.textFields?[0].text
			self.combine(withProposedTitle: proposedTitle)
		}
		
		dialog.addAction(cancelAction)
		dialog.addAction(saveAction)
		dialog.preferredAction = saveAction
		
		present(dialog, animated: true)
	}
	
	private func cancelCombineCollections() {
		// Revert sectionOfLibraryItems.
		// Revert the list of Collections.
		// (Revert the rest of the UI.)
		
		
	}
	
	private func combine(
//		_ oldCollections: [Collection],
		withProposedTitle proposedTitle: String?
	) {
		
		
	}
	
}
