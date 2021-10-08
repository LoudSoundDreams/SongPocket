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
	
	// Identical to counterpart in AlbumsTVC.
	final override func tableView(
		_ tableView: UITableView,
		numberOfRowsInSection section: Int
	) -> Int {
		setOrRemoveNoItemsBackground()
		
		return viewModel.numberOfRows(forSection: section)
	}
	
	// MARK: - Cells
	
	final override func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return UITableViewCell()
		}
		
		switch indexPath.row {
		case 0:
			return albumArtworkCell(forRowAt: indexPath)
		case 1:
			return albumInfoCell(forRowAt: indexPath)
		default:
			return songCell(forRowAt: indexPath)
		}
	}
	
	// MARK: Album Artwork Cell
	
	private func albumArtworkCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let album = (viewModel as? SongsViewModel)?.container(forSection: indexPath.section) else {
			return UITableViewCell()
		}
		
		// Artwork
		let representativeItem = album.mpMediaItemCollection()?.representativeItem
		let artworkImage = representativeItem?.artwork?.image(at: CGSize(
			width: UIScreen.main.bounds.width,
			height: UIScreen.main.bounds.width))
		
		// Make, configure, and return the cell.
		
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: "Album Artwork Cell",
			for: indexPath) as? AlbumArtworkCell
		else {
			return UITableViewCell()
		}
		
		cell.artworkImageView.image = artworkImage
		
		cell.accessibilityUserInputLabels = [""]
		
		return cell
	}
	
	// MARK: Album Info Cell
	
	private func albumInfoCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let album = (viewModel as? SongsViewModel)?.container(forSection: indexPath.section) else {
			return UITableViewCell()
		}
		
		// Album artist
		let albumArtist: String // Don't let this be nil.
		= album.albumArtistFormattedOrPlaceholder()
		
		// Release date
		let releaseDateString = album.releaseDateEstimateFormatted()
		
		// Make, configure, and return the cell.
		if let releaseDateString = releaseDateString {
			guard let cell = tableView.dequeueReusableCell(
				withIdentifier: "Album Info Cell",
				for: indexPath) as? AlbumInfoCell
			else {
				return UITableViewCell()
			}
			
			cell.albumArtistLabel.text = albumArtist
			cell.releaseDateLabel.text = releaseDateString
			
			cell.accessibilityUserInputLabels = [""]
			
			return cell
			
		} else { // We couldn't determine the album's release date.
			guard let cell = tableView.dequeueReusableCell(
				withIdentifier: "Album Info Cell Without Release Date",
				for: indexPath) as? AlbumInfoCellWithoutReleaseDate
			else {
				return UITableViewCell()
			}
			
			cell.albumArtistLabel.text = albumArtist
			
			cell.accessibilityUserInputLabels = [""]
			
			return cell
		}
	}
	
	// MARK: Song Cell
	
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
			let album = songsViewModel.container(forSection: indexPath.section)
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
			guard let song = viewModel.item(at: indexPath) as? Song else { return }
			if let selectedCell = tableView.cellForRow(at: indexPath) {
				showSongActions(for: song, popoverAnchorView: selectedCell)
			}
			// This leaves the row selected while the action sheet is onscreen, which I prefer.
			// You must eventually deselect the row in every possible branch from here.
		}
		
		super.tableView(
			tableView,
			didSelectRowAt: indexPath)
	}
	
}
