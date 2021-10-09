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
	
	var group: GroupOfLibraryItems { groups[Self.indexOfGroup] }
	
	init(
		context: NSManagedObjectContext,
		reflector: LibraryViewModelReflecting
	) {
		self.context = context
		self.reflector = reflector
		groups = [
			GroupOfCollectionsOrAlbums(
				entityName: Self.entityName,
				container: nil,
				context: context)
		]
	}
	
	// MARK: - UITableView
	
	// MARK: Numbers
	
	func numberOfSections() -> Int {
//		return CollectionsSection.allCases.count
		
		
		return 1
	}
	
	func numberOfRows(
		forSection section: Int,
		contentState: CollectionsContentState
	) -> Int {
//		guard let sectionCase = CollectionsSection(rawValue: section) else {
//			return 0
//		}
//
//		switch sectionCase {
//		case .all:
//			return 1
//		case .collections:
		
		
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
		
		
//		}
	}
	
	// MARK: Headers
	
	func header(forSection section: Int) -> String? {
//		guard let sectionCase = CollectionsSection(rawValue: section) else {
//			return nil
//		}
//
//		switch sectionCase {
//		case .all:
//			return nil
//		case .collections:
//			return LocalizedString.collections
//		}
		
		
		return nil
	}
	
	// MARK: Cells
	
	func cell(
		forRowAt indexPath: IndexPath,
		contentState: CollectionsContentState,
		isEditing: Bool,
		albumMoverClipboard: AlbumMoverClipboard?,
		isPlaying: Bool,
		renameFocusedCollectionAction: UIAccessibilityCustomAction,
		accentColor: AccentColor,
		tableView: UITableView
	) -> UITableViewCell {
//		guard let sectionCase = CollectionsSection(rawValue: indexPath.section) else {
//			return UITableViewCell()
//		}
//
//		switch sectionCase {
//		case .all:
//			return allCell(
//				forRowAt: indexPath,
//				contentState: contentState,
//				isEditing: isEditing,
//				tableView: tableView)
//		case .collections:
		
		
		switch contentState {
		case .allowAccess:
			guard let cell = tableView.dequeueReusableCell(
				withIdentifier: "Allow Access",
				for: indexPath) as? AllowAccessCell
			else {
				return UITableViewCell()
			}
			cell.configure(with: accentColor)
			return cell
		case .loading:
			return tableView.dequeueReusableCell(
				withIdentifier: "Loading",
				for: indexPath) as? LoadingCell ?? UITableViewCell()
		case .blank: // Should never run
			return UITableViewCell()
		case .noCollections:
			switch indexPath.row {
			case 0:
				return tableView.dequeueReusableCell(
					withIdentifier: "No Collections",
					for: indexPath) as? NoCollectionsPlaceholderCell ?? UITableViewCell()
			case 1:
				guard let cell = tableView.dequeueReusableCell(
					withIdentifier: "Open Music",
					for: indexPath) as? OpenMusicCell
				else {
					return UITableViewCell()
				}
				cell.configure(with: accentColor)
				return cell
			default: // Should never run
				return UITableViewCell()
			}
		case .oneOrMoreCollections:
			return collectionCell(
				forRowAt: indexPath,
				albumMoverClipboard: albumMoverClipboard,
				isPlaying: isPlaying,
				renameFocusedCollectionAction: renameFocusedCollectionAction,
				tableView: tableView)
		}
		
		
//		}
	}
	
	private func allCell(
		forRowAt indexPath: IndexPath,
		contentState: CollectionsContentState,
		isEditing: Bool,
		tableView: UITableView
	) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: "All",
			for: indexPath) as? AllCollectionsCell
		else {
			return UITableViewCell()
		}
		
		if isEditing {
			cell.accessoryType = .none
		} else {
			cell.accessoryType = .disclosureIndicator
			
			switch contentState {
			case .allowAccess, .loading, .blank, .noCollections:
				cell.allLabel.textColor = .placeholderText
				cell.disableWithAccessibilityTrait()
			case .oneOrMoreCollections:
				cell.allLabel.textColor = .label
				cell.enableWithAccessibilityTrait()
			}
		}
		
		return cell
	}
	
	private func collectionCell(
		forRowAt indexPath: IndexPath,
		albumMoverClipboard: AlbumMoverClipboard?,
		isPlaying: Bool,
		renameFocusedCollectionAction: UIAccessibilityCustomAction,
		tableView: UITableView
	) -> UITableViewCell {
		guard let collection = item(at: indexPath) as? Collection else {
			return UITableViewCell()
		}
		
		// "Now playing" indicator
		let isInPlayer = isInPlayer(libraryItemAt: indexPath)
		let nowPlayingIndicator = NowPlayingIndicator(
			isInPlayer: isInPlayer,
			isPlaying: isPlaying)
		
		// Make, configure, and return the cell.
		
		guard var cell = tableView.dequeueReusableCell(
			withIdentifier: "Collection",
			for: indexPath) as? CollectionCell
		else {
			return UITableViewCell()
		}
		
		let idOfSourceCollection = albumMoverClipboard?.idOfSourceCollection
		cell.configure(
			with: collection,
			isMovingAlbumsFromCollectionWith: idOfSourceCollection,
			renameFocusedCollectionAction: renameFocusedCollectionAction)
		cell.applyNowPlayingIndicator(nowPlayingIndicator)
		
		return cell
	}
	
	// MARK: Editing
	
	func canEditRow(
		at indexPath: IndexPath
	) -> Bool {
//		guard let sectionCase = CollectionsSection(rawValue: indexPath.section) else {
//			return false
//		}
//
//		switch sectionCase {
//		case .all:
//			return false
//		case .collections:
		
		
		return (self as LibraryViewModel).canEditRow(at: indexPath)
		
		
//		}
	}
	
	// MARK: Reordering
	
	func targetIndexPathForMovingRow(
		at sourceIndexPath: IndexPath,
		to proposedDestinationIndexPath: IndexPath
	) -> IndexPath {
//		guard let proposedSectionCase = CollectionsSection(rawValue: proposedDestinationIndexPath.section) else {
//			return sourceIndexPath
//		}
//
//		switch proposedSectionCase {
//		case .all:
//			return sourceIndexPath
//		case .collections:
		
		
		return (self as LibraryViewModel).targetIndexPathForMovingRow(
			at: sourceIndexPath,
			to: proposedDestinationIndexPath)
		
		
//		}
	}
	
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
	
	// Return value: whether this method changed the Collection's title.
	// Works for renaming an existing Collection, after combining Collections, and after making a new Collection.
	func rename(
		at indexPath: IndexPath,
		proposedTitle: String?
	) -> Bool {
		guard let collection = item(at: indexPath) as? Collection else {
			return false
		}
		
		let didChangeTitle = collection.rename(toProposedTitle: proposedTitle)
		return didChangeTitle
	}
	
	// MARK: - “Moving Albums” Mode
	
	// MARK: Making New
	
	func itemsAfterMakingNewCollection(
		suggestedTitle: String?,
		indexOfNewCollection: Int
	) -> [NSManagedObject] { // ? [Collection]
		let newCollection = Collection(context: context)
		newCollection.title = suggestedTitle ?? LocalizedString.newCollectionDefaultTitle
		// When we call setItemsAndMoveRows, the property observer will set the "index" attribute of each Collection for us.
		
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
