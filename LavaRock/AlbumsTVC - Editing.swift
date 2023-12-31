//
//  AlbumsTVC - Editing.swift
//  LavaRock
//
//  Created by h on 2021-07-04.
//

import UIKit
import CoreData

extension AlbumsTVC {
	// MARK: - Move to collection
	
	func startMoving() {
		// Prepare a Collections view to present modally.
		let nc = UINavigationController(
			rootViewController: UIStoryboard(name: "CollectionsTVC", bundle: nil)
				.instantiateInitialViewController()!
		)
		guard
			let collectionsTVC = nc.viewControllers.first as? CollectionsTVC,
			let selfVM = viewModel as? AlbumsViewModel
		else { return }
		
		// Configure the `CollectionsTVC`.
		collectionsTVC.moveAlbumsClipboard = MoveAlbumsClipboard(albumsBeingMoved: {
			var subjectedRows: [Int] = tableView.selectedIndexPaths.map { $0.row }
			subjectedRows.sort()
			if subjectedRows.isEmpty {
				subjectedRows = selfVM.rowsForAllItems()
			}
			return subjectedRows.map {
				selfVM.albumNonNil(atRow: $0)
			}
		}())
		collectionsTVC.viewModel = CollectionsViewModel(context: {
			let childContext = NSManagedObjectContext(.mainQueue)
			childContext.parent = viewModel.context
			return childContext
		}())
		
		present(nc, animated: true)
	}
}
