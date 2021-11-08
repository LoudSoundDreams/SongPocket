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
	
	// Identical to counterpart in SongsTVC.
	final override func tableView(
		_ tableView: UITableView,
		numberOfRowsInSection section: Int
	) -> Int {
		setOrRemoveNoItemsBackground()
		
		func numberOfRowsForAlbumGroupSection() -> Int {
			return viewModel.numberOfRows(forSection: section)
		}
		
		if FeatureFlag.allRow {
			let sectionKind = SectionKind(forSection: section)
			switch sectionKind {
			case .all:
				return 1
			case .groupOfAlbums:
				return numberOfRowsForAlbumGroupSection()
			}
		} else {
			return numberOfRowsForAlbumGroupSection()
		}
	}
	
	// MARK: - Headers
	
	final override func tableView(
		_ tableView: UITableView,
		titleForHeaderInSection section: Int
	) -> String? {
		if FeatureFlag.allRow {
			let sectionKind = SectionKind(forSection: section)
			switch sectionKind {
			case .all:
				return nil
			case .groupOfAlbums:
				if viewModel.isSpecificallyOpenedContainer {
					// We're showing a single `Collection`, and the user specifically chose it.
					return LocalizedString.albums
				} else {
					// The user tapped "All" at some point to get here, so use container titles for each group of `Album`s.
					return (viewModel as? AlbumsViewModel)?.collection(forSection: section).title
				}
			}
		} else {
			return nil
		}
	}
	
	// MARK: - Cells
	
	final override func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		func cellForRowInAlbumGroupSection() -> UITableViewCell {
			return albumCell(forRowAt: indexPath)
		}
		
		if FeatureFlag.allRow {
			let sectionKind = SectionKind(forSection: indexPath.section)
			switch sectionKind {
			case .all:
				return allCell(forRowAt: indexPath)
			case .groupOfAlbums:
				return cellForRowInAlbumGroupSection()
			}
		} else {
			return cellForRowInAlbumGroupSection()
		}
	}
	
	private func allCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: "These Albums",
			for: indexPath) as? TheseContainersCell
		else {
			return UITableViewCell()
		}
		
		if albumMoverClipboard != nil {
			cell.configure(mode: .disabledWithNoDisclosureIndicator)
		} else {
			if isEditing {
				cell.configure(mode: .disabledWithNoDisclosureIndicator)
			} else {
				if viewModel.isEmpty() {
					cell.configure(mode: .disabledWithDisclosureIndicator)
				} else {
					cell.configure(mode: .enabled)
				}
			}
		}
		
		return cell
	}
	
	private func albumCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let album = viewModel.item(at: indexPath) as? Album else {
			return UITableViewCell()
		}
		
		// "Now playing" indicator
		let isInPlayer = isInPlayer(libraryItemAt: indexPath)
		let isPlaying = sharedPlayer?.playbackState == .playing
		let nowPlayingIndicator = NowPlayingIndicator(
			isInPlayer: isInPlayer,
			isPlaying: isPlaying)
		
		// Make, configure, and return the cell.
		
		guard var cell = tableView.dequeueReusableCell(
			withIdentifier: "Album",
			for: indexPath) as? AlbumCell
		else {
			return UITableViewCell()
		}
		
		let mode: AlbumCell.Mode = {
			if let albumMoverClipboard = albumMoverClipboard {
				if albumMoverClipboard.idsOfAlbumsBeingMoved_asSet.contains(album.objectID) {
					return .movingAlbumsModeAndBeingMoved
				} else {
					return .movingAlbumsModeAndNotBeingMoved
				}
			} else {
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
		if albumMoverClipboard != nil {
			return false
		} else {
			return super.tableView(
				tableView,
				shouldBeginMultipleSelectionInteractionAt: indexPath)
		}
	}
	
}
