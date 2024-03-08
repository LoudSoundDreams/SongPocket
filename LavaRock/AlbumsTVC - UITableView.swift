//
//  AlbumsTVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit
import SwiftUI

extension AlbumsTVC {
	// MARK: - Numbers
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		if viewModel.isEmpty() {
			contentUnavailableConfiguration = UIHostingConfiguration {
				Image(systemName: "square.stack")
					.foregroundStyle(.secondary)
					.font(.title)
			}
			.margins(.all, .zero)
		} else {
			contentUnavailableConfiguration = nil
		}
		
		return viewModel.groups.count
	}
	
	override func tableView(
		_ tableView: UITableView, numberOfRowsInSection section: Int
	) -> Int {
		let albumsViewModel = viewModel as! AlbumsViewModel
		if albumsViewModel.collection == nil {
			return 0 // Without `prerowCount`
		} else {
			return albumsViewModel.prerowCount() + albumsViewModel.libraryGroup().items.count
		}
	}
	
	// MARK: - Cells
	
	override func tableView(
		_ tableView: UITableView, cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		// The cell in the storyboard is completely default except for the reuse identifier and selection segue.
		let cell = tableView.dequeueReusableCell(withIdentifier: "Album Card", for: indexPath)
		let album = (viewModel as! AlbumsViewModel).albumNonNil(atRow: indexPath.row)
		let (mode, enabled) = new_albumRowMode_and_selectionStyle(album: album)
		cell.backgroundColors_configureForLibraryItem()
		cell.isUserInteractionEnabled = enabled
		if enabled {
			cell.accessibilityTraits.subtract(.notEnabled)
		} else {
			cell.accessibilityTraits.formUnion(.notEnabled)
		}
		cell.contentConfiguration = UIHostingConfiguration {
			AlbumRow(
				album: album,
				maxHeight: {
					let height = view.frame.height
					let topInset = view.safeAreaInsets.top
					let bottomInset = view.safeAreaInsets.bottom
					return height - topInset - bottomInset
				}(),
				mode: mode)
		}
		.margins(.all, .zero)
		return cell
	}
	func new_albumRowMode_and_selectionStyle(album: Album) -> (
		mode: AlbumRow.Mode,
		enabled: Bool
	) {
		let mode: AlbumRow.Mode = {
			switch purpose {
				case .movingAlbums(let clipboard):
					if clipboard.idsOfAlbumsBeingMovedAsSet.contains(album.objectID) {
						return .disabledTinted
					}
					return .disabled
				case .browsing:
					return .normal
			}
		}()
		let enabled: Bool = {
			switch purpose {
				case .movingAlbums: return false
				case .browsing: return true
			}
		}()
		return (mode, enabled)
	}
}
