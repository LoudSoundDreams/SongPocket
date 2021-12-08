//
//  SongsTVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit
import MediaPlayer

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
	
//	final override func tableView(
//		_ tableView: UITableView,
//		viewForHeaderInSection section: Int
//	) -> UIView? {
//		guard let album = (viewModel as? SongsViewModel)?.album(forSection: section) else {
//			return UITableViewCell()
//		}
//
//		guard let cell = tableView.dequeueReusableCell(
//			withIdentifier: "Album Info")
//				as? AlbumInfoCell
//		else {
//			return UITableViewCell()
//		}
//		cell.configure(with: album)
//		return cell
//	}
	
	final override func tableView(
		_ tableView: UITableView,
		titleForHeaderInSection section: Int
	) -> String? {
		if FeatureFlag.multialbum {
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
		switch indexPath.row {
		case 0:
			return albumArtworkCell(forRowAt: indexPath)
		case 1:
			return albumInfoCell(forRowAt: indexPath)
		default:
			return songCell(forRowAt: indexPath)
		}
	}
	
	private func albumArtworkCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let album = (viewModel as? SongsViewModel)?.album(forSection: indexPath.section) else {
			return UITableViewCell()
		}
		
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: "Album Artwork",
			for: indexPath) as? AlbumArtworkCell
		else {
			return UITableViewCell()
		}
		cell.configure(with: album)
		return cell
	}
	
	private func albumInfoCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let album = (viewModel as? SongsViewModel)?.album(forSection: indexPath.section) else {
			return UITableViewCell()
		}
		
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: "Album Info",
			for: indexPath) as? AlbumInfoCell
		else {
			return UITableViewCell()
		}
		cell.configure(with: album)
		return cell
	}
	
	private func songCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let songsViewModel = viewModel as? SongsViewModel
		else { return UITableViewCell() }
		
		let song = songsViewModel.songNonNil(at: indexPath)
		let mediaItem = song.mpMediaItem() // Can be `nil` if the user recently deleted the media item from their library
		
		let album = songsViewModel.album(forSection: indexPath.section)
		let representativeItem = album.mpMediaItemCollection()?.representativeItem
		
		// "Now playing" indicator
		let isInPlayer = isInPlayer(anyIndexPath: indexPath)
		let isPlaying = sharedPlayer?.playbackState == .playing
		let nowPlayingIndicator = NowPlayingIndicator(
			isInPlayer: isInPlayer,
			isPlaying: isPlaying)
		
		guard var cell = tableView.dequeueReusableCell(
			withIdentifier: "Song",
			for: indexPath) as? SongCell
		else {
			return UITableViewCell()
		}
		
		cell.configureWith(
			mediaItem: mediaItem,
			albumRepresentative: representativeItem)
		cell.applyNowPlayingIndicator(nowPlayingIndicator)
		
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
			}
			// This leaves the row selected while the action sheet is onscreen, which I prefer.
			// You must eventually deselect the row in every possible branch from here.
		}
		
		super.tableView(tableView, didSelectRowAt: indexPath)
	}
	
}
