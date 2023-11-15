//
//  AlbumsTVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit
import SwiftUI

struct NoAlbumsView: View {
	var body: some View {
		Text(LRString.noAlbums)
			.foregroundStyle(.secondary)
			.font(.title)
	}
}
extension AlbumsTVC {
	// MARK: - Numbers
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		if viewModel.isEmpty() {
			tableView.backgroundView = UIHostingController(rootView: NoAlbumsView()).view
		} else {
			tableView.backgroundView = nil
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
		cell.backgroundColor = .clear
		let album = (viewModel as! AlbumsViewModel).albumNonNil(atRow: indexPath.row)
		let (mode, selectionStyle) = new_albumCardMode_and_selectionStyle(album: album)
		cell.selectionStyle = selectionStyle
		cell.contentConfiguration = UIHostingConfiguration {
			AlbumCard(
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
	func new_albumCardMode_and_selectionStyle(album: Album) -> (
		mode: AlbumCard.Mode,
		selectionStyle: UITableViewCell.SelectionStyle
	) {
		let mode: AlbumCard.Mode = {
			switch purpose {
				case .previewingCombine:
					return .disabledTinted
				case .organizingAlbums(let clipboard):
					if clipboard.subjectedAlbums_ids.contains(album.objectID) {
						return .disabledTinted
					}
					return .disabled
				case .movingAlbums(let clipboard):
					if clipboard.idsOfAlbumsBeingMovedAsSet.contains(album.objectID) {
						return .disabledTinted
					}
					return .disabled
				case .browsing:
					return .normal
			}
		}()
		let selectionStyle: UITableViewCell.SelectionStyle = {
			switch mode {
				case .normal: return .default
				case .disabled, .disabledTinted: return .none
			}
		}()
		return (mode, selectionStyle)
	}
	
	// MARK: - Selecting
	
	override func tableView(
		_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath
	) -> Bool {
		switch purpose {
			case .previewingCombine, .organizingAlbums, .movingAlbums: return false
			case .browsing: return super.tableView(tableView, shouldBeginMultipleSelectionInteractionAt: indexPath)
		}
	}
	
	override func tableView(
		_ tableView: UITableView, willSelectRowAt indexPath: IndexPath
	) -> IndexPath? {
		switch purpose {
			case .previewingCombine, .organizingAlbums, .movingAlbums: return nil
			case .browsing: return super.tableView(tableView, willSelectRowAt: indexPath)
		}
	}
}
