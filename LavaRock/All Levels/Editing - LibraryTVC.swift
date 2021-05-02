//
//  Editing - LibraryTVC.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData

extension LibraryTVC {
	
	final override func setEditing(
		_ editing: Bool,
		animated: Bool
	) {
		if isEditing {
			managedObjectContext.tryToSave()
		}
		
		super.setEditing(editing, animated: animated)
		
		refreshAndSetBarButtons(animated: animated)
		
		// Makes the cells resize themselves (expand if text has wrapped around to new lines; shrink if text has unwrapped into fewer lines).
		// Otherwise, they'll stay the same size until they reload some other time, like after you edit them or they leave memory.
		tableView.performBatchUpdates(nil)
	}
	
	// Note: We handle rearranging in UITableViewDataSource and UITableViewDelegate methods.
	
	// MARK: - Allowing
	
	// You should only be allowed to sort contiguous items within the same SectionOfLibraryItems.
	final func shouldAllowSorting() -> Bool {
		if tableView.indexPathsF0rSelectedRows.isEmpty {
			return true // Multisection: Only if we only have 1 SectionOfLibraryItems.
		} else {
			return tableView.indexPathsF0rSelectedRows.isContiguousWithinSameSection()
		}
	}
	
	final func shouldAllowFloating() -> Bool {
		return
			!tableView.indexPathsF0rSelectedRows.isEmpty &&
			tableView.indexPathsF0rSelectedRows.isWithinSameSection()
	}
	
	final func shouldAllowSinking() -> Bool {
		return shouldAllowFloating()
	}
	
	// MARK: - Moving to Top
	
	@objc final func floatSelectedItemsToTopOfSection() {
		guard shouldAllowFloating() else { return }
		
		// Make a new data source.
		
		let selectedIndexPaths = tableView.indexPathsF0rSelectedRows.sorted()
		let indexesOfSelectedItems = selectedIndexPaths.map { indexOfLibraryItem(for: $0) }
		let selectedItems = selectedIndexPaths.map { libraryItem(for: $0) }
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
			completion: {
				self.tableView.deselectAllRows(animated: true)
				self.refreshBarButtons()
			})
	}
	
	// MARK: - Moving to Bottom
	
	@objc final func sinkSelectedItemsToBottomOfSection() {
		guard shouldAllowSinking() else { return }
		
		// Make a new data source.
		
		let selectedIndexPaths = tableView.indexPathsF0rSelectedRows.sorted()
		let indexesOfSelectedItems = selectedIndexPaths.map { indexOfLibraryItem(for: $0) }
		let selectedItems = selectedIndexPaths.map { libraryItem(for: $0) }
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
			completion: {
				self.tableView.deselectAllRows(animated: true)
				self.refreshBarButtons()
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
		
		present(actionSheet, animated: true)
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
		guard shouldAllowSorting() else { return }
		
		// Get the indexes of the items to sort.
		let sourceIndexPaths: [IndexPath]
		if tableView.indexPathsF0rSelectedRows.isEmpty {
			sourceIndexPaths = indexPaths(forIndexOfSectionOfLibraryItems: 0)
		} else {
			sourceIndexPaths = tableView.indexPathsF0rSelectedRows.sorted()
		}
		let sourceIndexesOfItems = sourceIndexPaths.map { indexOfLibraryItem(for: $0) }
		
		// Get the items to sort.
		let itemsToSort = sourceIndexesOfItems.map { sectionOfLibraryItems.items[$0] }
		
		// Sort the items.
		let sortedItems = sorted(
			itemsToSort,
			sortOptionLocalizedName: sortOptionLocalizedName)
		
		// Make a new data source.
		var newItems = sectionOfLibraryItems.items
		for index in sourceIndexesOfItems.reversed() {
			newItems.remove(at: index)
		}
		for i in sortedItems.indices {
			let sortedItem = sortedItems[i]
			let destinationIndex = sourceIndexesOfItems[i]
			newItems.insert(sortedItem, at: destinationIndex)
		}
		
		// Update the data source and table view.
		setItemsAndRefreshTableView(
			newItems: newItems,
			completion: {
				self.tableView.deselectAllRows(animated: true)
				self.refreshBarButtons()
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
					return collectionTitle0.precedesInAlphabeticalOrderFinderStyle(collectionTitle1)
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
			
		case LocalizedString.reverse:
			return items.reversed()
			
		default:
			print("The user tried to sort by “\(sortOptionLocalizedName ?? "")”, which isn’t a supported option. It might be misspelled.")
			return items
		}
	}
	
}
