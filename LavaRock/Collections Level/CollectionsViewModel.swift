//
//  CollectionsViewModel.swift
//  CollectionsViewModel
//
//  Created by h on 2021-08-14.
//

import UIKit
import CoreData

struct CollectionsViewModel: LibraryViewModel {
	
	// MARK: - LibraryViewModel
	
	static let entityName = "Collection"
//	static let numberOfSectionsAboveLibraryItems = 1
	static let numberOfSectionsAboveLibraryItems = 0
	static let numberOfRowsAboveLibraryItemsInEachSection = 0
	
	let context: NSManagedObjectContext
	
	weak var reflector: LibraryViewModelReflecting?
	
	var groups: [GroupOfLibraryItems]
	
	func navigationItemTitleOptional() -> String? {
//		return "Library" // TO DO: Localize
		return nil
	}
	
	// MARK: - Miscellaneous
	
//	private enum CollectionsSection: Int, CaseIterable {
//		case all
//		case collections
//	}
	
	static let indexOfGroup = 0 //
	
//	var group: GroupOfLibraryItems {
//		get { groups[0] }
//		set { groups[0] = newValue }
//	}
//	var group: GroupOfLibraryItems { groups[0] }
	var group: GroupOfLibraryItems { groups[Self.indexOfGroup] }
//	var groupOfCollectionsBeforeCombining: GroupOfLibraryItems?
	
	init(
		context: NSManagedObjectContext,
		reflector: LibraryViewModelReflecting
	) {
		self.context = context
		self.reflector = reflector
		groups = [ // CollectionsViewModel will only have one GroupOfLibraryItems
			GroupOfCollectionsOrAlbums(
				entityName: Self.entityName,
				container: nil,
				context: context)
		]
	}
	
	/*
	// MARK: - UITableView
	
	// MARK: Numbers
	
	func numberOfSections() -> Int {
		return CollectionsSection.allCases.count
	}
	
	func numberOfRows(
		forSection section: Int,
		contentState: CollectionsContentState
	) -> Int {
		guard let sectionCase = CollectionsSection(rawValue: section) else {
			return 0
		}
		
		switch sectionCase {
		case .all:
			return 1
		case .collections:
			switch contentState {
			case .allowAccess, .loading:
				return 1
			case .blank:
				return 0
			case .noCollections:
				return 2
			case .oneOrMoreCollections:
				return (self as LibraryViewModel).numberOfRows(forSection: section)
			}
		}
	}
	
	// MARK: Headers
	
	func header(
		forSection section: Int
	) -> String? {
		guard let sectionCase = CollectionsSection(rawValue: section) else {
			return nil
		}
		
		switch sectionCase {
		case .all:
			return nil
		case .collections:
			return LocalizedString.collections
		}
	}
	
	// MARK: Editing
	
	func canEditRow(
		at indexPath: IndexPath
	) -> Bool {
		guard let sectionCase = CollectionsSection(rawValue: indexPath.section) else {
			return false
		}
		
		switch sectionCase {
		case .all:
			return false
		case .collections:
			return (self as LibraryViewModel).canEditRow(at: indexPath) // TO DO: Does this work?
		}
	}
	
	// MARK: Reordering
	
	func targetIndexPathForMovingRow(
		at sourceIndexPath: IndexPath,
		to proposedDestinationIndexPath: IndexPath
	) -> IndexPath {
		guard let proposedSectionCase = CollectionsSection(rawValue: proposedDestinationIndexPath.section) else {
			return sourceIndexPath
		}
		
		switch proposedSectionCase {
		case .all:
			return sourceIndexPath
		case .collections:
			return (self as LibraryViewModel).targetIndexPathForMovingRow( // TO DO: Does this work?
				at: sourceIndexPath,
				to: proposedDestinationIndexPath)
		}
	}
	*/
	
	// MARK: - Editing
	
	// MARK: Combining
	
	func allowsCombine(
		selectedIndexPaths: [IndexPath]
	) -> Bool {
		guard !isEmpty() else {
			return false
		}
		
		return selectedIndexPaths.count >= 2
	}
	
//	func isPreviewingCombineCollections() -> Bool {
//		return groupOfCollectionsBeforeCombining != nil
//	}
	
	func itemsAfterCombiningCollections(
		from selectedIndexPaths: [IndexPath],
		into indexPathOfCombinedCollection: IndexPath
	) -> [NSManagedObject] {
//		// Save the existing GroupOfCollectionsOrAlbums for if we need to revert, and to prevent ourselves from starting another preview while we're already previewing.
//		groupOfCollectionsBeforeCombining = group // SIDE EFFECT
		
		// Create the combined Collection.
		let selectedCollections = selectedIndexPaths.compactMap { item(at: $0) as? Collection }
		let indexOfCombinedCollection = indexOfItemInGroup(forRow: indexPathOfCombinedCollection.row)
		let combinedCollection = Collection.makeByCombining_withoutDeletingOrReindexing( // SIDE EFFECT
			selectedCollections,
			title: LocalizedString.combinedCollectionDefaultTitle,
			index: Int64(indexOfCombinedCollection),
			context: context)
		// WARNING: We still need to delete empty Collections and reindex all Collections.
		// Do that later, when we commit, because if we revert, we have to restore the original Collections, and Core Data warns you if you mutate managed objects after deleting them.
		try? context.obtainPermanentIDs( // SIDE EFFECT
			for: [combinedCollection]) // So that the "now playing" indicator can appear on the combined Collection.
		
		// Make a new data source.
		var newItems = group.items
		let indicesOfSelectedCollections = selectedIndexPaths.map {
			indexOfItemInGroup(forRow: $0.row)
		}
		indicesOfSelectedCollections.reversed().forEach { newItems.remove(at: $0) }
		newItems.insert(combinedCollection, at: indexOfCombinedCollection)
		return newItems
	}
	
	// MARK: - Renaming
	
	// Works for renaming an existing Collection, after combining Collections, and after making a new Collection.
	func itemsAfterRenamingCollection(
		at indexPath: IndexPath,
		proposedTitle: String?
	) -> (
		items: [NSManagedObject],
		didChangeTitle: Bool
	) {
		let items = group(forSection: indexPath.section).items
		
		guard let collection = item(at: indexPath) as? Collection else {
			return (items, false)
		}
		
		let oldTitle = collection.title
		if let newTitle = Collection.validatedTitleOptional(from: proposedTitle) {
			collection.title = newTitle
		}
		let didChangeTitle = oldTitle != collection.title
		
		return (items, didChangeTitle)
	}
	
	// MARK: - “Moving Albums” Mode
	
	// MARK: Making New
	
	func itemsAfterMakingNewCollection(
		suggestedTitle: String?,
		indexOfNewCollection: Int
	) -> [NSManagedObject] { // ? [Collection]
		let newCollection = Collection(context: context)
		newCollection.title = suggestedTitle ?? LocalizedString.newCollectionDefaultTitle
		// When we call setItemsAndRefresh, the property observer will set the "index" attribute of each Collection for us.
		
		var newItems = group.items
		newItems.insert(newCollection, at: indexOfNewCollection)
		return newItems
	}
	
	// MARK: Deleting New
	
	func itemsAfterDeletingCollection(
		indexOfCollection: Int
	) -> [NSManagedObject] { // ? [Collection]
		let oldItems = group.items
		guard
			let collection = oldItems[indexOfCollection] as? Collection,
			collection.isEmpty()
		else {
			return oldItems
		}
		
		context.delete(collection)
		
		var newItems = group.items
		newItems.remove(at: indexOfCollection)
		return newItems
	}
	
}
