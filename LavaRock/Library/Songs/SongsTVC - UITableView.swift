//
//  SongsTVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit

extension SongsTVC {
	// MARK: - Numbers
	
	// Identical to counterpart in `AlbumsTVC`.
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
	
	final override func tableView(
		_ tableView: UITableView,
		titleForHeaderInSection section: Int
	) -> String? {
		if Enabling.multialbum {
			return (viewModel as? SongsViewModel)?.album(forSection: section).titleFormattedOrPlaceholder()
		} else {
			return nil
		}
	}
	
	// MARK: - Cells
	
	final override func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		guard let songsViewModel = viewModel as? SongsViewModel else { return UITableViewCell() }
		let rowCase = songsViewModel.rowCase(for: indexPath)
		switch rowCase {
		case .prerow(let prerow):
			switch prerow {
			case .albumArtwork:
				guard let cell = tableView.dequeueReusableCell(
					withIdentifier: "Album Artwork",
					for: indexPath) as? AlbumArtworkCell
				else { return UITableViewCell() }
				let album = songsViewModel.album(forSection: indexPath.section)
				cell.configure(with: album)
				return cell
			case .albumInfo:
				if Enabling.wholeAlbumButtons {
					guard let cell = tableView.dequeueReusableCell(
						withIdentifier: "Album Info with Buttons",
						for: indexPath) as? AlbumInfoCell__withWholeAlbumButtons
					else { return UITableViewCell() }
					let album = songsViewModel.album(forSection: indexPath.section)
					cell.album = album
					return cell
				} else {
					guard let cell = tableView.dequeueReusableCell(
						withIdentifier: "Album Info",
						for: indexPath) as? AlbumInfoCell
					else { return UITableViewCell() }
					let album = songsViewModel.album(forSection: indexPath.section)
					cell.configure(with: album)
					return cell
				}
			}
		case .song:
			break
		}
		
		guard var cell = tableView.dequeueReusableCell(
			withIdentifier: "Song",
			for: indexPath) as? SongCell
		else { return UITableViewCell() }
		
		cell.configureWith(
			metadatum: {
				let song = songsViewModel.songNonNil(at: indexPath)
				return song.metadatum() // Can be `nil` if the user recently deleted the `SongMetadatum` from their library
			}(),
			albumRepresentative: {
				let album = songsViewModel.album(forSection: indexPath.section)
				return album.representativeMPMediaItem()
			}())
		cell.applyNowPlayingIndicator(
			NowPlayingIndicator(
				isInPlayer: isInPlayer(anyIndexPath: indexPath),
				isPlaying: player?.playbackState == .playing))
		
		return cell
	}
	
	// MARK: - Selecting
	
	final override func tableView(
		_ tableView: UITableView,
		didSelectRowAt indexPath: IndexPath
	) {
		if isEditing {
		} else {
			if
				let song = viewModel.itemNonNil(at: indexPath) as? Song,
				let selectedCell = tableView.cellForRow(at: indexPath)
			{
				showSongActions(for: song, popoverAnchorView: selectedCell)
				// This leaves the row selected while the action sheet is onscreen, which I prefer.
				// You must eventually deselect the row in every possible branch from here.
			}
		}
		
		super.tableView(tableView, didSelectRowAt: indexPath)
	}
}
