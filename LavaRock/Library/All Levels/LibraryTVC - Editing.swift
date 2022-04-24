//
//  LibraryTVC - Editing.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit

extension LibraryTVC {
	final func makeSortOptionsMenu() -> UIMenu {
		let groupedElements: [[UIMenuElement]] = sortOptionsGrouped.map { sortOptionGroup in
			let groupOfChildren: [UIMenuElement] = sortOptionGroup.map { sortOption in
				let action = UIAction(
					title: sortOption.localizedName(),
					image: sortOption.uiImage()
				) { [weak self] action in
					self?.sortSelectedOrAllItems(sortOptionLocalizedName: action.title)
				}
				
				return UIDeferredMenuElement.uncached({ [weak self] useMenuElements in
					guard let self = self else { return }
					let allowed: Bool = {
						let viewModel = self.viewModel
						let indexPathsToSort = viewModel.unsortedOrForAllItemsIfNoneSelectedAndViewContainerIsSpecific(
							selectedIndexPaths: self.tableView.indexPathsForSelectedRowsNonNil)
						let items = indexPathsToSort.map { viewModel.itemNonNil(at: $0) }
						return viewModel.allowsSortOption(sortOption, forItems: items)
					}()
					action.attributes = allowed ? [] : .disabled
					useMenuElements([action])
				})
			}
			return groupOfChildren
		}
		
		return UIMenu(
			title: {
				let formatString: String? = {
					switch self {
					case is CollectionsTVC:
						return LocalizedString.format_xCollections
					case is AlbumsTVC:
						return LocalizedString.format_xAlbums
					case is SongsTVC:
						return LocalizedString.format_xSongs
					default:
						return nil
					}
				}()
				guard let formatString = formatString else {
					return ""
				}
				let subjectedCount = viewModel
					.unsortedOrForAllItemsIfNoneSelectedAndViewContainerIsSpecific(
						selectedIndexPaths: tableView.indexPathsForSelectedRowsNonNil)
					.count
				return String.localizedStringWithFormat(
					formatString,
					subjectedCount)
			}(),
			presentsUpward: true,
			groupedElements: groupedElements)
	}
	
	private func sortSelectedOrAllItems(sortOptionLocalizedName: String) {
		let newViewModel = viewModel.updatedAfterSorting(
			selectedIndexPaths: tableView.indexPathsForSelectedRowsNonNil,
			sortOptionLocalizedName: sortOptionLocalizedName)
		Task {
			let _ = await setViewModelAndMoveRowsAndShouldContinue(newViewModel)
		}
	}
	
	final func floatSelectedItemsToTopOfSection() {
		let newViewModel = viewModel.updatedAfterFloatingToTopsOfSections(
			selectedIndexPaths: tableView.indexPathsForSelectedRowsNonNil)
		Task {
			let _ = await setViewModelAndMoveRowsAndShouldContinue(newViewModel)
		}
	}
	
	final func sinkSelectedItemsToBottomOfSection() {
		let newViewModel = viewModel.updatedAfterSinkingToBottomsOfSections(
			selectedIndexPaths: tableView.indexPathsForSelectedRowsNonNil)
		Task {
			let _ = await setViewModelAndMoveRowsAndShouldContinue(newViewModel)
		}
	}
}
