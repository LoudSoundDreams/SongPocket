//
//  AlbumsTVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit

extension AlbumsTVC {
	// MARK: - Numbers
	
	final override func numberOfSections(in tableView: UITableView) -> Int {
		setOrRemoveNoItemsBackground()
		
		switch purpose {
		case .organizingAlbums:
			break
		case .movingAlbums(let clipboard):
			if clipboard.didAlreadyCreate {
				return viewModel.numberOfPresections.value + 1
			} else {
				break
			}
		case .browsing:
			break
		}
		
		return super.numberOfSections(in: tableView)
	}
	
	final override func tableView(
		_ tableView: UITableView,
		numberOfRowsInSection section: Int
	) -> Int {
		return viewModel.numberOfRows(for: Section_I(section))
	}
	
	// MARK: - Headers
	
//	final override func tableView(
//		_ tableView: UITableView,
//		viewForHeaderInSection section: Int
//	) -> UIView? {
//
//
//		guard let cell = tableView.dequeueReusableCell(
//			withIdentifier: "Album Group Header")
//				//				as?
//		else { UITableViewCell() }
//
//		return cell
//	}
	
	final override func tableView(
		_ tableView: UITableView,
		titleForHeaderInSection section: Int
	) -> String? {
		if Enabling.multicollection {
			return (viewModel as? AlbumsViewModel)?
				.collection(for: Section_I(section))
				.title
		} else {
			return nil
		}
	}
	
	// MARK: - Cells
	
	final override func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		guard let albumsViewModel = viewModel as? AlbumsViewModel else { return UITableViewCell() }
		
		switch purpose {
		case .organizingAlbums:
			break
		case .movingAlbums:
			let rowCase = albumsViewModel.rowCase(for: indexPath)
			switch rowCase {
			case .prerow(let prerow):
				switch prerow {
				case .moveHere:
					return tableView.dequeueReusableCell(
						withIdentifier: "Move Here",
						for: indexPath) as? MoveHereCell ?? UITableViewCell()
				}
			case .album:
				break
			}
		case .browsing:
			break
		}
		
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: "Album",
			for: indexPath) as? AlbumCell
		else { return UITableViewCell() }
		
		let album = albumsViewModel.albumNonNil(at: indexPath)
		cell.configure(
			with: album,
			mode: {
				switch purpose {
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
				}}())
		
		return cell
	}
	
	// MARK: - Selecting
	
	final override func tableView(
		_ tableView: UITableView,
		shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath
	) -> Bool {
		switch purpose {
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
	
	final override func tableView(
		_ tableView: UITableView,
		willSelectRowAt indexPath: IndexPath
	) -> IndexPath? {
		switch purpose {
		case .organizingAlbums:
			break
		case .movingAlbums:
			guard let albumsViewModel = viewModel as? AlbumsViewModel else {
				return nil
			}
			let rowCase = albumsViewModel.rowCase(for: indexPath)
			switch rowCase {
			case .prerow(let prerow):
				switch prerow {
				case .moveHere:
					return indexPath
				}
			case .album:
				break
			}
		case .browsing:
			break
		}
		
		return super.tableView(tableView, willSelectRowAt: indexPath)
	}
	
	final override func tableView(
		_ tableView: UITableView,
		didSelectRowAt indexPath: IndexPath
	) {
		switch purpose {
		case .organizingAlbums:
			break
		case .movingAlbums:
			guard let albumsViewModel = viewModel as? AlbumsViewModel else { return }
			let rowCase = albumsViewModel.rowCase(for: indexPath)
			switch rowCase {
			case .prerow(let prerow):
				switch prerow {
				case .moveHere:
					moveHere(to: indexPath)
					return
				}
			case .album:
				break
			}
		case .browsing:
			break
		}
		
		super.tableView(tableView, didSelectRowAt: indexPath)
	}
}
