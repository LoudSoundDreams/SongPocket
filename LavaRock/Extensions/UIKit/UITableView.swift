//
//  UITableView.swift
//  LavaRock
//
//  Created by h on 2020-08-06.
//

import UIKit

extension UITableView {
	// MARK: - Sections
	
	final func allSections() -> [Section_I] {
		return (0 ..< numberOfSections).map { section in
			Section_I(section)
		}
	}
	
	// MARK: IndexPaths
	
	final var visibleIndexPaths: [IndexPath] {
		return indexPathsForVisibleRows ?? []
	}
	
	final var selectedIndexPaths: [IndexPath] {
		return indexPathsForSelectedRows ?? []
	}
	
	final func allIndexPaths() -> [IndexPath] {
		return allSections().flatMap { section in
			indexPathsForRows(in: section, first: Row_I(0))
		}
	}
	
	final func indexPathsForRows(
		in section: Section_I,
		first: Row_I
	) -> [IndexPath] {
		let lastRow = Row_I(numberOfRows(inSection: section.value) - 1)
		guard lastRow.value >= 0 else {
			// The section has 0 rows.
			return []
		}
		return Self.indexPathsForRows(
			in: section,
			first: first,
			last: lastRow)
	}
	
	private static func indexPathsForRows(
		in section: Section_I,
		first: Row_I,
		last: Row_I
	) -> [IndexPath] {
		return (first.value ... last.value).map { row in
			IndexPath(Row_I(row), in: section)
		}
	}
	
	// MARK: - Updating
	
	final func applyBatchUpdates(
		firstReloading toReload: [IndexPath],
		with reloadAnimation: RowAnimation,
		thenMovingSections sectionUpdates: BatchUpdates<Int>,
		andRows rowUpdates: [BatchUpdates<IndexPath>],
		with moveAnimation: RowAnimation,
		runningBeforeContinuation beforeContinuation: (() -> Void)? = nil
	) async {
		await withCheckedContinuation { (
			continuation: CheckedContinuation<Void, _>
		) in
			applyBatchUpdates__completion(
				firstReloading: toReload,
				with: reloadAnimation,
				thenMovingSections: sectionUpdates,
				andRows: rowUpdates,
				with: moveAnimation
			) {
				continuation.resume()
			}
			beforeContinuation?()
		}
	}
	
	final func applyBatchUpdates__completion(
		firstReloading toReload: [IndexPath],
		with reloadAnimation: RowAnimation,
		thenMovingSections sectionUpdates: BatchUpdates<Int>,
		andRows rowUpdates: [BatchUpdates<IndexPath>],
		with moveAnimation: RowAnimation,
		completion: @escaping () -> Void
	) {
		let rowsToDelete = rowUpdates.flatMap { $0.toDelete }
		let rowsToInsert = rowUpdates.flatMap { $0.toInsert }
		let rowsToMove = rowUpdates.flatMap { $0.toMove }
		
		performBatchUpdates {
			reloadRows(at: toReload, with: reloadAnimation)
			
			deleteSections(IndexSet(sectionUpdates.toDelete), with: moveAnimation)
			deleteRows(at: rowsToDelete, with: moveAnimation)
			
			insertSections(IndexSet(sectionUpdates.toInsert), with: moveAnimation)
			insertRows(at: rowsToInsert, with: moveAnimation)
			
			// Do *not* skip `moveSection` or `moveRow` even if the old and new indices are the same.
			sectionUpdates.toMove.forEach { (sourceIndex, destinationIndex) in
				moveSection(sourceIndex, toSection: destinationIndex)
			}
			rowsToMove.forEach { (sourceIndexPath, destinationIndexPath) in
				moveRow(at: sourceIndexPath, to: destinationIndexPath)
			}
		} completion: { _ in
			completion()
		}
	}
	
	@discardableResult
	final func performBatchUpdates__async(
		_ updates: (() -> Void)?,
		runningBeforeContinuation beforeContinuation: (() -> Void)? = nil
	) async -> Bool {
		await withCheckedContinuation { continuation in
			performBatchUpdates(
				updates
			) { didCompleteAnimationsSuccessfully in
				continuation.resume(returning: didCompleteAnimationsSuccessfully)
			}
			beforeContinuation?()
		}
	}
	
	final func reloadRows__async(
		at toReload: [IndexPath],
		with animation: RowAnimation
	) async -> Bool {
		return await performBatchUpdates__async {
			self.reloadRows(at: toReload, with: animation)
		}
	}
	
	final func deselectAllRows(animated: Bool) {
		selectedIndexPaths.forEach {
			deselectRow(at: $0, animated: animated)
		}
	}
}
