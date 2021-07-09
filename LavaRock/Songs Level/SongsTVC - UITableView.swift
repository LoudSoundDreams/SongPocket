//
//  SongsTVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit
import MediaPlayer

extension SongsTVC {
	
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
		// Get the data to put into the cell.
		guard let album = sectionOfLibraryItems.container as? Album else {
			return UITableViewCell()
		}
		let representativeItem = album.mpMediaItemCollection()?.representativeItem
		let cellImage = representativeItem?.artwork?.image(at: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width))
		
		// Make, configure, and return the cell.
		
		guard let albumArtworkCell = tableView.dequeueReusableCell(
			withIdentifier: "Album Artwork Cell",
			for: indexPath)
				as? AlbumArtworkCell
		else {
			return UITableViewCell()
		}
		albumArtworkCell.artworkImageView.image = cellImage
		
		albumArtworkCell.accessibilityUserInputLabels = [""]
		
		return albumArtworkCell
	}
	
	// MARK: Album Info Cell
	
	private func albumInfoCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		// Get the data to put into the cell.
		guard let album = sectionOfLibraryItems.container as? Album else {
			return UITableViewCell()
		}
		let cellHeading = album.albumArtistFormattedOrPlaceholder()
		let cellSubtitle = album.releaseDateEstimateFormatted()
		
		// Make, configure, and return the cell.
		if let cellSubtitle = cellSubtitle {
			guard let albumInfoCell = tableView.dequeueReusableCell(
				withIdentifier: "Album Info Cell",
				for: indexPath)
					as? AlbumInfoCell
			else {
				return UITableViewCell()
			}
			albumInfoCell.albumArtistLabel.text = cellHeading
			albumInfoCell.releaseDateLabel.text = cellSubtitle
			
			albumInfoCell.accessibilityUserInputLabels = [""]
			
			return albumInfoCell
			
		} else { // We couldn't determine the album's release date.
			guard let albumInfoCell = tableView.dequeueReusableCell(
				withIdentifier: "Album Info Cell Without Release Date",
				for: indexPath)
					as? AlbumInfoCellWithoutReleaseDate
			else {
				return UITableViewCell()
			}
			albumInfoCell.albumArtistLabel.text = cellHeading
			
			albumInfoCell.accessibilityUserInputLabels = [""]
			
			return albumInfoCell
		}
	}
	
	// MARK: Song Cell
	
	private func songCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		// Get the data to put into the cell.
		guard let song = libraryItem(for: indexPath) as? Song else {
			return UITableViewCell()
		}
		let mediaItem = song.mpMediaItem()
		
		let cellTitle = mediaItem?.title ?? Song.titlePlaceholder
		
		let isInPlayer = isInPlayer(libraryItemFor: indexPath)
		let isPlaying = sharedPlayer?.playbackState == .playing
		let nowPlayingIndicator = NowPlayingIndicator(
			isInPlayer: isInPlayer,
			isPlaying: isPlaying)
		
		let cellTrackNumberText: String = {
			guard let mediaItem = mediaItem else {
				return Song.trackNumberPlaceholder
			}
			let trackNumberText = String(mediaItem.albumTrackNumber)
			if
				let sectionOfSongs = sectionOfLibraryItems as? SectionOfSongs,
				sectionOfSongs.shouldShowDiscNumbers
			{
				let discNumberText = String(mediaItem.discNumber)
				return discNumberText + "-" /*hyphen*/ + trackNumberText
			} else {
				return trackNumberText
			}
		}()
		
		// Make, configure, and return the cell.
		let albumArtist = (sectionOfLibraryItems.container as? Album)?.albumArtist() // Can be nil
		if
			let songArtist = mediaItem?.artist,
			songArtist != albumArtist
		{
			guard var cell = tableView.dequeueReusableCell(
				withIdentifier: "Cell with Different Artist",
				for: indexPath)
					as? SongCellWithDifferentArtist
			else {
				return UITableViewCell()
			}
			
			cell.titleLabel.text = cellTitle
			
			cell.artistLabel.text = songArtist
			
			cell.apply(nowPlayingIndicator)
			cell.trackNumberLabel.text = cellTrackNumberText
			cell.trackNumberLabel.font = UIFont.bodyWithMonospacedNumbers // This doesn't work if you set it in cell.awakeFromNib().
			
			cell.accessibilityUserInputLabels = [cellTitle]
			
			return cell
			
		} else { // The song's artist is not useful, or it's the same as the album artist.
			guard var cell = tableView.dequeueReusableCell(
				withIdentifier: cellReuseIdentifier,
				for: indexPath)
					as? SongCell
			else {
				return UITableViewCell()
			}
			
			cell.titleLabel.text = cellTitle
			
			cell.apply(nowPlayingIndicator)
			cell.trackNumberLabel.text = cellTrackNumberText
			cell.trackNumberLabel.font = UIFont.bodyWithMonospacedNumbers // This doesn't work if you set it in cell.awakeFromNib().
			
			cell.accessibilityUserInputLabels = [cellTitle]
			
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
			guard let song = libraryItem(for: indexPath) as? Song else { return }
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
