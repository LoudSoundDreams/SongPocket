//
//  Editing - LibraryTVC.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData

extension LibraryTVC {
	
	final override func setEditing(_ editing: Bool, animated: Bool) {
		if isEditing {
			managedObjectContext.tryToSave()
		}
		
		super.setEditing(editing, animated: animated)
		
		refreshAndSetBarButtons(animated: animated)
		
		// Makes the cells resize themselves (expand if text has wrapped around to new lines; shrink if text has unwrapped into fewer lines).
		// Otherwise, they'll stay the same size until they reload some other time, like after you edit them or they leave memory.
		tableView.performBatchUpdates(nil, completion: nil)
	}
	
	// Note: We handle rearranging in UITableViewDataSource and UITableViewDelegate methods.
	
	// MARK: - Moving to Top
	
	@objc final func moveSelectedItemsToTop() {
		guard
			tableView.shouldAllowMovingSelectedRowsToTopOfSection(),
			let indexPaths = tableView.indexPathsForSelectedRows?.sorted()
		else { return }
		
		// Make a new data source.
		
		let indexesOfSelectedItems = indexPaths.map { indexOfLibraryItem(for: $0) }
		let selectedItems = indexPaths.map { libraryItem(for: $0) }
		var newItems = sectionOfLibraryItems.items
		for index in indexesOfSelectedItems.reversed() {
			newItems.remove(at: index)
		}
		
		for item in selectedItems.reversed() {
			newItems.insert(item, at: 0)
		}
		
		// Update the data source and table view.
		setItemsAndRefreshTableView(
			newItems: newItems,
			completion: { [self] in
				tableView.deselectAllRows(animated: true)
				refreshBarButtons()
			})
	}
	
	// MARK: - Moving to Bottom
	
	@objc final func sinkSelectedItemsToBottom() {
		guard
			tableView.shouldAllowMovingSelectedRowsToBottomOfSection(),
			let indexPaths = tableView.indexPathsForSelectedRows?.sorted()
		else { return }
		
		// Make a new data source.
		
		let indexesOfSelectedItems = indexPaths.map { indexOfLibraryItem(for: $0) }
		let selectedItems = indexPaths.map { libraryItem(for: $0) }
		var newItems = sectionOfLibraryItems.items
		for index in indexesOfSelectedItems.reversed() {
			newItems.remove(at: index)
		}
		
		for item in selectedItems {
			newItems.append(item)
		}
		
		// Update the data source and table view.
		setItemsAndRefreshTableView(
			newItems: newItems,
			completion: { [self] in
				tableView.deselectAllRows(animated: true)
				refreshBarButtons()
			})
	}
	
	// MARK: - Sorting
	
	// For iOS 13
	@objc final func showSortOptionsActionSheet() {
		let actionSheet = UIAlertController(
			title: LocalizedString.sortBy,
			message: nil,
			preferredStyle: .actionSheet)
		for sortOption in sortOptions {
			actionSheet.addAction(
				UIAlertAction(
					title: sortOption.localizedName(),
					style: .default,
					handler: sortSelectedOrAllItems(_:)))
		}
		actionSheet.addAction(
			UIAlertAction(
				title: LocalizedString.cancel,
				style: .cancel,
				handler: nil)
		)
		actionSheet.popoverPresentationController?.barButtonItem = sortButton
		
		present(actionSheet, animated: true, completion: nil)
	}
	
	// For iOS 13
	private func sortSelectedOrAllItems(_ sender: UIAlertAction) {
		guard let sortOptionLocalizedName = sender.title else { return }
		sortSelectedOrAllItems(sortOptionLocalizedName: sortOptionLocalizedName)
	}
	
	// For iOS 14 and later
	final func sortActionHandler(_ sender: UIAction) {
		sortSelectedOrAllItems(sortOptionLocalizedName: sender.title)
	}
	
	private func sortSelectedOrAllItems(sortOptionLocalizedName: String) {
		guard tableView.shouldAllowSorting() else { return }
		
		// Get the rows to sort.
		let indexPathsToSort = tableView.selectedOrEnumeratedIndexPathsIn(
			section: 0,
			firstRow: numberOfRowsAboveLibraryItems)
		guard !indexPathsToSort.isEmpty else { return }
		
		// Get and sort the items.
		let itemsToSort = indexPathsToSort.map { libraryItem(for: $0) }
		let sortedItems = sorted(
			itemsToSort,
			sortOptionLocalizedName: sortOptionLocalizedName)
		
		// Make a new data source.
		let indexes = indexPathsToSort.map { indexOfLibraryItem(for: $0) }
		var newItems = sectionOfLibraryItems.items
		for index in indexes.reversed() {
			newItems.remove(at: index)
		}
		for i in 0 ..< sortedItems.count {
			let sortedItem = sortedItems[i]
			let index = indexes[i]
			newItems.insert(sortedItem, at: index)
		}
		
		// Update the data source and table view.
		setItemsAndRefreshTableView(newItems: newItems, completion: { [self] in
			tableView.deselectAllRows(animated: true)
			refreshBarButtons()
		})
	}
	
	// Sorting should be stable! Multiple items with the same name, disc number, or whatever property we're sorting by should stay in the same order.
	private func sorted(
		_ items: [NSManagedObject],
		sortOptionLocalizedName: String?
	) -> [NSManagedObject] {
		switch sortOptionLocalizedName {
		
		case LocalizedString.title:
			if let collections = items as? [Collection] {
				return collections.sorted {
					// Don't sort by <. It puts all capital letters before all lowercase letters, meaning "Z" comes before "a".
					let collectionTitle0 = $0.title ?? ""
					let collectionTitle1 = $1.title ?? ""
					let comparisonResult = collectionTitle0.localizedStandardCompare(collectionTitle1) // The comparison method that the Finder uses
					return comparisonResult == .orderedAscending
				}
			} else {
				// If we're sorting Albums or Songs, use titleFormattedOrPlaceholder().
				return items
			}
		
		// Albums only
		case LocalizedString.newestFirst:
			guard let albums = items as? [Album] else {
				return items
			}
			let commonDate = Date()
			return albums.sorted {
				$0.releaseDateEstimate ?? commonDate >
					$1.releaseDateEstimate ?? commonDate
			}
		case LocalizedString.oldestFirst:
			guard let albums = items as? [Album] else {
				return items
			}
			let commonDate = Date()
			return albums.sorted {
				$0.releaseDateEstimate ?? commonDate <
					$1.releaseDateEstimate ?? commonDate
			}
		
		// Songs only
		case LocalizedString.trackNumber:
			guard let songs = items as? [Song] else {
				return items
			}
			// Actually, return the songs grouped by disc number, and sorted by track number within each disc.
			let sortedByTrackNumber = songs.sorted {
				$0.mpMediaItem()?.albumTrackNumber ?? 0 <
					$1.mpMediaItem()?.albumTrackNumber ?? 0
			}
			let sortedByTrackNumberWithZeroAtEnd = sortedByTrackNumber.sorted {
				$1.mpMediaItem()?.albumTrackNumber ?? 0 == 0
			}
			let sortedByDiscNumber = sortedByTrackNumberWithZeroAtEnd.sorted {
				$0.mpMediaItem()?.discNumber ?? 0 <
					$1.mpMediaItem()?.discNumber ?? 0
			}
			// As of iOS 14.0 beta 5, MediaPlayer reports unknown disc numbers as 1, so there's no need to move disc 0 to the end.
			return sortedByDiscNumber
			
		default:
			print("The user tried to sort by “\(sortOptionLocalizedName ?? "")”, which isn’t a supported option. It might be misspelled.")
			return items
		}
	}
	
}
