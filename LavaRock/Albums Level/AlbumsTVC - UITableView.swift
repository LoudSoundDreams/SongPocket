//
//  AlbumsTVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit
import MediaPlayer

extension AlbumsTVC {
	
	// MARK: - Numbers
	
	// Identical to counterpart in `SongsTVC`.
	final override func numberOfSections(in tableView: UITableView) -> Int {
		setOrRemoveNoItemsBackground()
		
		return super.numberOfSections(in: tableView)
	}
	
	final override func tableView(
		_ tableView: UITableView,
		numberOfRowsInSection section: Int
	) -> Int {
		return viewModel.numberOfRows(forSection: section)
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
//		else {
//			return UITableViewCell()
//		}
//
//		return cell
//	}
	
	final override func tableView(
		_ tableView: UITableView,
		titleForHeaderInSection section: Int
	) -> String? {
		if FeatureFlag.multicollection {
			return (viewModel as? AlbumsViewModel)?.collection(forSection: section).title
		} else {
			return nil
		}
	}
	
	// MARK: - Cells
	
	final override func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		switch purpose {
		case .organizingAlbums:
			break
		case .movingAlbums:
			if indexPath.row < viewModel.numberOfPrerowsPerSection {
				return tableView.dequeueReusableCell(
					withIdentifier: "Move Here",
					for: indexPath) as? MoveHereCell ?? UITableViewCell()
			} else {
				break
			}
		case .browsing:
			break
		}
		
		return albumCell(forRowAt: indexPath)
	}
	
	private func albumCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let album = viewModel.itemNonNil(at: indexPath) as? Album else {
			return UITableViewCell()
		}
		
		// "Now playing" indicator
		let isInPlayer = isInPlayer(anyIndexPath: indexPath)
		let isPlaying = sharedPlayer?.playbackState == .playing
		let nowPlayingIndicator = NowPlayingIndicator(
			isInPlayer: isInPlayer,
			isPlaying: isPlaying)
		
		guard var cell = tableView.dequeueReusableCell(
			withIdentifier: "Album",
			for: indexPath) as? AlbumCell
		else {
			return UITableViewCell()
		}
		
		let mode: AlbumCell.Mode = {
			switch purpose {
			case .organizingAlbums(let clipboard):
				if clipboard.idsOfOrganizedAlbums.contains(album.objectID) {
					return .modalTinted
				} else {
					return .modalNotTinted
				}
			case .movingAlbums(let clipboard):
				if clipboard.idsOfAlbumsBeingMoved_asSet.contains(album.objectID) {
					return .modalTinted
//					return .movingAlbumsModeAndBeingMoved
				} else {
					return .modalNotTinted
//					return .movingAlbumsModeAndNotBeingMoved
				}
			case .browsing:
				return .normal
			}
		}()
		cell.configure(
			with: album,
			mode: mode)
		cell.applyNowPlayingIndicator(nowPlayingIndicator)
		
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
			if indexPath.row < viewModel.numberOfPrerowsPerSection {
				return indexPath
			} else {
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
			if indexPath.row < viewModel.numberOfPrerowsPerSection {
				moveHere()
			} else {
				break
			}
		case .browsing:
			break
		}
		
		super.tableView(tableView, didSelectRowAt: indexPath)
	}
	
}
