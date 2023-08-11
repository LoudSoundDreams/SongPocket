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
		_ tableView: UITableView,
		numberOfRowsInSection section: Int
	) -> Int {
		let albumsViewModel = viewModel as! AlbumsViewModel
		if albumsViewModel.folder == nil {
			return 0 // Without `prerowCount`
		} else {
			return albumsViewModel.prerowCount() + albumsViewModel.libraryGroup().items.count
		}
	}
	
	// MARK: - Cells
	
	override func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		let albumsViewModel = viewModel as! AlbumsViewModel
		
		switch purpose {
			case .previewingCombine:
				break
			case .organizingAlbums:
				break
			case .movingAlbums:
				let rowCase = albumsViewModel.rowCase(for: indexPath)
				switch rowCase {
					case .prerow:
						// The cell in the storyboard is completely default except for the reuse identifier.
						let cell = tableView.dequeueReusableCell(withIdentifier: "Move Here", for: indexPath)
						cell.contentConfiguration = UIHostingConfiguration {
							HStack {
								Text(LRString.moveHere)
									.foregroundStyle(Color.accentColor)
									.bold()
								Spacer()
							}
							.accessibilityAddTraits(.isButton)
							.alignmentGuide_separatorTrailing()
						}
						return cell
					case .album:
						break
				}
			case .browsing:
				break
		}
		
		let album = albumsViewModel.albumNonNil(atRow: indexPath.row)
		let mode: AlbumRowMode = {
			switch purpose {
				case .previewingCombine:
					return .modalTinted
				case .organizingAlbums(let clipboard):
					if clipboard.idsOfSubjectedAlbums.contains(album.objectID) {
						return .modalTinted
					} else {
						return .modal
					}
				case .movingAlbums(let clipboard):
					if clipboard.idsOfAlbumsBeingMovedAsSet.contains(album.objectID) {
						return .modalTinted
					} else {
						return .modal
					}
				case .browsing:
					return .normal
			}
		}()
		if AlbumCell.usesSwiftUI__ {
			let cell = tableView.dequeueReusableCell(withIdentifier: "Album", for: indexPath)
			cell.contentConfiguration = UIHostingConfiguration {
				AlbumRow(album: album, mode: mode)
			}
			.margins(.vertical, 0)
			return cell
		} else {
			guard let cell = tableView.dequeueReusableCell(
				withIdentifier: "Album",
				for: indexPath) as? AlbumCell
			else { return UITableViewCell() }
			cell.configure(with: album, mode: mode)
			return cell
		}
	}
	
	// MARK: - Selecting
	
	override func tableView(
		_ tableView: UITableView,
		shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath
	) -> Bool {
		switch purpose {
			case .previewingCombine:
				return false
			case .organizingAlbums:
				return false
			case .movingAlbums:
				return false
			case .browsing:
				return super.tableView(
					tableView,
					shouldBeginMultipleSelectionInteractionAt: indexPath)
		}
	}
	
	override func tableView(
		_ tableView: UITableView,
		willSelectRowAt indexPath: IndexPath
	) -> IndexPath? {
		switch purpose {
			case .previewingCombine:
				return nil
			case .organizingAlbums:
				return nil
			case .movingAlbums:
				let albumsViewModel = viewModel as! AlbumsViewModel
				let rowCase = albumsViewModel.rowCase(for: indexPath)
				switch rowCase {
					case .prerow:
						return indexPath
					case .album:
						return nil
				}
			case .browsing:
				break
		}
		
		return super.tableView(tableView, willSelectRowAt: indexPath)
	}
	
	override func tableView(
		_ tableView: UITableView,
		didSelectRowAt indexPath: IndexPath
	) {
		switch purpose {
			case .previewingCombine:
				break
			case .organizingAlbums:
				break
			case .movingAlbums:
				let albumsViewModel = viewModel as! AlbumsViewModel
				let rowCase = albumsViewModel.rowCase(for: indexPath)
				switch rowCase {
					case .prerow:
						moveHere()
						return
					case .album:
						break
				}
			case .browsing:
				break
		}
		
		super.tableView(tableView, didSelectRowAt: indexPath)
	}
}