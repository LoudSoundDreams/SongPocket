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
//		// Make, configure, and return the cell.
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
		if FeatureFlag.allRow {
			if viewModel.viewContainerIsSpecific {
				return nil
			} else {
				// The user tapped "All" at some point to get here, so use container titles for each group of `Song`s.
				return (viewModel as? SongsViewModel)?.album(forSection: section).titleFormattedOptional()
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
		
		// Make, configure, and return the cell.
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
		
		// Make, configure, and return the cell.
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
		guard let song = viewModel.item(at: indexPath) as? Song else {
			return UITableViewCell()
		}
		
		let mediaItem = song.mpMediaItem()
		
		// Title
		let songTitle = mediaItem?.title
		
		guard let songsViewModel = viewModel as? SongsViewModel else {
			return UITableViewCell()
		}
		
		// Artist
		let songArtist: String? = {
			let album = songsViewModel.album(forSection: indexPath.section)
			let albumArtist = album.albumArtist() // Can be nil
			if
				let songArtist = mediaItem?.artist,
				songArtist != albumArtist
			{
				return songArtist
			} else {
				return nil
			}
		}()
		
		// "Now playing" indicator
		let isInPlayer = isInPlayer(libraryItemAt: indexPath)
		let isPlaying = sharedPlayer?.playbackState == .playing
		let nowPlayingIndicator = NowPlayingIndicator(
			isInPlayer: isInPlayer,
			isPlaying: isPlaying)
		
		// Track number
		let shouldShowDiscNumbers = songsViewModel.shouldShowDiscNumbers(forSection: indexPath.section)
		let trackNumberString: String // Don't let this be nil.
		= mediaItem?.trackNumberFormatted(includeDisc: shouldShowDiscNumbers)
		?? MPMediaItem.placeholderTrackNumber
		
		// Make, configure, and return the cell.
		
		guard var cell = tableView.dequeueReusableCell(
			withIdentifier: "Song",
			for: indexPath) as? SongCell
		else {
			return UITableViewCell()
		}
		
		cell.configureWith(
			title: songTitle,
			artist: songArtist,
			trackNumberString: trackNumberString)
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
				let song = viewModel.item(at: indexPath) as? Song,
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
