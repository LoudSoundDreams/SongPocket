//
//  CollectionsTVC - Editing.swift
//  LavaRock
//
//  Created by h on 2020-08-23.
//

import UIKit
import CoreData

extension CollectionsTVC {
	
	// MARK: - Renaming
	
	final func confirmRename(at indexPath: IndexPath) {
		guard let collection = viewModel.itemNonNil(at: indexPath) as? Collection else { return }
		
		let rowWasSelectedBeforeRenaming = tableView.indexPathsForSelectedRowsNonNil.contains(indexPath)
		
		let dialog = UIAlertController.forEditingCollectionTitle(
			alertTitle: FeatureFlag.multicollection ? LocalizedString.renameSectionAlertTitle : LocalizedString.renameCollectionAlertTitle,
			textFieldText: collection.title,
			cancelHandler: nil,
			saveHandler: { textFieldText in
				self.rename(
					at: indexPath,
					proposedTitle: textFieldText,
					andSelectRowIf: rowWasSelectedBeforeRenaming)
			}
		)
		present(dialog, animated: true)
	}
	
	private func rename(
		at indexPath: IndexPath,
		proposedTitle: String?,
		andSelectRowIf shouldSelectRow: Bool
	) {
		guard let collectionsViewModel = viewModel as? CollectionsViewModel else { return }
		
		let didRename = collectionsViewModel.rename(
			at: indexPath,
			proposedTitle: proposedTitle)
		
		collectionsViewModel.context.tryToSave()
		
		if didRename {
			tableView.reloadRows(at: [indexPath], with: .fade)
		}
		if shouldSelectRow {
			tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
		}
	}
	
	// MARK: - Combining
	
	final func combineAndConfirm() {
		let selectedIndexPaths = tableView.indexPathsForSelectedRowsNonNil.sorted()
		guard
			let collectionsViewModel = viewModel as? CollectionsViewModel,
			viewModelBeforeCombining == nil, // Prevents you from using the "Combine" button multiple times quickly without dealing with the dialog first. This pattern is similar to checking `didAlreadyCreate` when we tap "New Collection", `didAlreadyCommitMove` for "Move (Albums) Here", and `didAlreadyCommitOrganize` for "Save (Preview of Organized Albums)".
			// You must reset `viewModelBeforeCombining = nil` during both reverting and committing.
			let indexPathOfCombined = selectedIndexPaths.first
		else { return }
		
		let selectedCollections = selectedIndexPaths.map {
			collectionsViewModel.collectionNonNil(at: $0)
		}
		let smartTitle = Self.smartCollectionTitle(combining: selectedCollections)
		combine(
			inOrder: selectedCollections,
			into: indexPathOfCombined,
			smartTitle: smartTitle)
		// I would prefer waiting for the table view to complete its animation before presenting the dialog. However, during the table view animation, you can tap other editing buttons, which can put our app into an incoherent state.
		// Whatever the case, creating a new `Collection` should use the same animation timing.
		confirmCombine(
			fromInOrder: selectedIndexPaths,
			into: indexPathOfCombined,
			smartTitle: smartTitle)
	}
	
	private static func smartCollectionTitle(
		combining collections: [Collection]
	) -> String? {
		let titles = collections.compactMap { $0.title }
		guard let firstTitle = titles.first else {
			return nil
		}
		let restOfTitles = titles.dropFirst()
		
		// Check whether the titles of the `Collection`s we're combining are all identical.
		if restOfTitles.allSatisfy({ $0 == firstTitle }) {
			return firstTitle
		}
		
		// Check whether the titles of the `Collection`s we're combining all start with the same thing.
		/*
	titleCommonPrefix: do {
		let commonPrefixTrimmed = titles.commonPrefix().trimmingWhitespaceAtEnd()
		
		guard let context = collections.first?.managedObjectContext else {
			break titleCommonPrefix
		}
		let existingTitles: Set<String> = {
			let allCollections = Collection.allFetched(ordered: false, via: context)
			return Set(allCollections.compactMap { $0.title })
		}()
		guard !existingTitles.contains(commonPrefixTrimmed) else {
			break titleCommonPrefix
		}
		
		// If we're combining `Collection`s titled "John Williams" and "Joe", suggesting "Jo" isn't useful and looks stupid.
		// TO DO: Internationalize. Not all languages separate words with whitespace.
		let commonPrefixLength = commonPrefixTrimmed.count
		let commonPrefixTrimmedIsAtWordBoundary = titles.allSatisfy {
			$0.endsOrHasWhitespaceAfter(dropFirstCount: commonPrefixLength)
		}
		if commonPrefixTrimmedIsAtWordBoundary {
			return commonPrefixTrimmed
		}
	}
		*/
		
		// Otherwise, give up.
		return nil
	}
	
	private func combine(
		inOrder collections: [Collection],
		into indexPathOfCombined: IndexPath,
		smartTitle: String?
	) {
		let collectionsViewModel = viewModel as! CollectionsViewModel
		
		viewModelBeforeCombining = collectionsViewModel
		
		let title = smartTitle ?? (FeatureFlag.multicollection ? LocalizedString.combinedSectionDefaultTitle : LocalizedString.combinedCollectionDefaultTitle)
		let newViewModel = collectionsViewModel.updatedAfterCombining_inNewChildContext(
			fromInOrder: collections,
			into: indexPathOfCombined,
			title: title)
		setViewModelAndMoveRows(
			newViewModel,
			andSelectRowsAt: [indexPathOfCombined])
	}
	
	private func confirmCombine(
		fromInOrder originalSelectedIndexPaths: [IndexPath],
		into indexPathOfCombined: IndexPath,
		smartTitle: String?
	) {
		let dialog = UIAlertController.forEditingCollectionTitle(
			alertTitle: FeatureFlag.multicollection ? LocalizedString.combineSectionsAlertTitle : LocalizedString.combineCollectionsAlertTitle,
			textFieldText: smartTitle,
			cancelHandler: {
				self.revertCombine(andSelectRowsAt: originalSelectedIndexPaths)
			},
			saveHandler: { textFieldText in
				self.commitCombine(
					into: indexPathOfCombined,
					proposedTitle: textFieldText)
			}
		)
		present(dialog, animated: true)
	}
	
	final func revertCombine(
		andSelectRowsAt originalSelectedIndexPaths: [IndexPath]
	) {
		guard let originalViewModel = viewModelBeforeCombining else { return }
		
		viewModelBeforeCombining = nil
		
		setViewModelAndMoveRows(
			originalViewModel,
			andSelectRowsAt: Set(originalSelectedIndexPaths))
	}
	
	private func commitCombine(
		into indexPathOfCombined: IndexPath,
		proposedTitle: String?
	) {
		guard let collectionsViewModel = viewModel as? CollectionsViewModel else { return }
		
		viewModelBeforeCombining = nil
		
		let didRename = collectionsViewModel.rename(
			at: indexPathOfCombined,
			proposedTitle: proposedTitle)
		
		collectionsViewModel.context.tryToSave()
		collectionsViewModel.context.parent!.tryToSave()
		
		let newViewModel = CollectionsViewModel(
			context: collectionsViewModel.context.parent!,
			prerowsInEachSection: collectionsViewModel.prerowsInEachSection)
		viewModel = newViewModel // As of iOS 15.2 developer beta 3, even though `setViewModelAndMoveRows` also sets `viewModel` and doesn't move any rows, it breaks the animation for `reloadRows` below.
		
		if didRename {
			tableView.reloadRows(at: [indexPathOfCombined], with: .fade)
		}
	}
	
}
