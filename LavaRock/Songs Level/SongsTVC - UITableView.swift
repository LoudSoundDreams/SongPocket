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
		let albumArtist: String = album.albumArtistFormattedOrPlaceholder() // Don't let this be nil.
		
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
		let songTitle: String // Don't let this be nil.
		= mediaItem?.title ?? MPMediaItem.placeholderTitle
		
		// "Now playing" indicator
		let isInPlayer = isInPlayer(libraryItemFor: indexPath)
		let isPlaying = sharedPlayer?.playbackState == .playing
		let nowPlayingIndicator = NowPlayingIndicator(
			isInPlayer: isInPlayer,
			isPlaying: isPlaying)
		
		guard let songsViewModel = viewModel as? SongsViewModel else {
			return UITableViewCell()
		}
		
		// Track number
		let shouldShowDiscNumbers = songsViewModel.shouldShowDiscNumbers(forSection: indexPath.section)
		let trackNumberString: String // Don't let this be nil.
		= mediaItem?.trackNumberFormatted(includeDisc: shouldShowDiscNumbers)
		?? MPMediaItem.placeholderTrackNumber
		
		// Artist
		let album = songsViewModel.container(forSection: indexPath.section)
		let albumArtist = album.albumArtist() // Can be nil
		
		// Make, configure, and return the cell.
		if
			let songArtist = mediaItem?.artist,
			songArtist != albumArtist
		{
			guard var cell = tableView.dequeueReusableCell(
				withIdentifier: "Cell with Different Artist",
				for: indexPath) as? SongCellWithDifferentArtist
			else {
				return UITableViewCell()
			}
			
			cell.titleLabel.text = songTitle
			
			cell.artistLabel.text = songArtist
			
			cell.apply(nowPlayingIndicator)
			cell.trackNumberLabel.text = trackNumberString
			cell.trackNumberLabel.font = UIFont.bodyWithMonospacedNumbers // This doesn't work if you set it in cell.awakeFromNib().
			
			cell.accessibilityUserInputLabels = [songTitle]
			
			return cell
			
		} else { // The song's artist is not useful, or it's the same as the album artist.
			guard var cell = tableView.dequeueReusableCell(
				withIdentifier: Self.libraryItemCellReuseIdentifier,
				for: indexPath) as? SongCell
			else {
				return UITableViewCell()
			}
			
			cell.titleLabel.text = songTitle
			
			cell.apply(nowPlayingIndicator)
			cell.trackNumberLabel.text = trackNumberString
			cell.trackNumberLabel.font = UIFont.bodyWithMonospacedNumbers // This doesn't work if you set it in cell.awakeFromNib().
			
			cell.accessibilityUserInputLabels = [songTitle]
			
			return cell
		}
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
