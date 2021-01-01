//
//  UITableView - SongsTVC.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit
import MediaPlayer

extension SongsTVC {
	
	// MARK: - Cells
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return UITableViewCell()
		}
		
		if indexPath.row == 0 {
			
			// Get the data to put into the cell.
			let album = containerOfLibraryItems as! Album
			let representativeItem = album.mpMediaItemCollection()?.representativeItem
			let cellImage = representativeItem?.artwork?.image(at: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width))
			
			// Make, configure, and return the cell.
			let albumArtworkCell = tableView.dequeueReusableCell(withIdentifier: "Album Artwork Cell") as! AlbumArtworkCell
			albumArtworkCell.artworkImageView.image = cellImage
			return albumArtworkCell
			
		} else if indexPath.row == 1 {
			
			// Get the data to put into the cell.
			let album = containerOfLibraryItems as! Album
			let cellHeading = album.albumArtistFormattedOrPlaceholder()
			let cellSubtitle = album.releaseDateEstimateFormatted()
			
			// Make, configure, and return the cell.
			if let cellSubtitle = cellSubtitle {
				let albumInfoCell = tableView.dequeueReusableCell(withIdentifier: "Album Info Cell") as! AlbumInfoCell
				albumInfoCell.albumArtistLabel.text = cellHeading
				albumInfoCell.releaseDateLabel.text = cellSubtitle
				return albumInfoCell
				
			} else { // We couldn't determine the album's release date.
				let albumInfoCell = tableView.dequeueReusableCell(withIdentifier: "Album Info Cell Without Release Date") as! AlbumInfoCellWithoutReleaseDate
				albumInfoCell.albumArtistLabel.text = cellHeading
				return albumInfoCell
			}
			
		} else {
			
			// Get the data to put into the cell.
			let song = indexedLibraryItems[indexPath.row - numberOfRowsAboveIndexedLibraryItems] as! Song
			let cellTitle = song.titleFormattedOrPlaceholder()
			let isNowPlayingSong = isNowPlayingItem(at: indexPath)
			let cellNowPlayingIndicator = nowPlayingIndicator(isNowPlayingItem: isNowPlayingSong)
			let cellTrackNumberText = song.trackNumberFormattedOrPlaceholder()
			
			// Make, configure, and return the cell.
			if
				let cellArtist = song.artistFormatted(),
				cellArtist != (containerOfLibraryItems as! Album).albumArtistFormattedOrPlaceholder()
			{
				var cell = tableView.dequeueReusableCell(withIdentifier: "Cell with Different Artist", for: indexPath) as! SongCellWithDifferentArtist
				cell.artistLabel.text = cellArtist
				
				cell.titleLabel.text = cellTitle
				cell.applyNowPlayingIndicator(cellNowPlayingIndicator)
				cell.trackNumberLabel.text = cellTrackNumberText
				cell.trackNumberLabel.font = UIFont.bodyMonospacedNumbers
				return cell
				
			} else { // The song's artist is not useful, or it's the same as the album artist.
				var cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! SongCell // As of some beta of iOS 14.0, UIListContentConfiguration.valueCell() doesn't gracefully accommodate multiple lines of text.
				
				cell.titleLabel.text = cellTitle
				cell.applyNowPlayingIndicator(cellNowPlayingIndicator)
				cell.trackNumberLabel.text = cellTrackNumberText
				cell.trackNumberLabel.font = UIFont.bodyMonospacedNumbers
				return cell
			}
			
		}
	}
	
	// MARK: - Selecting
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		super.tableView(tableView, didSelectRowAt: indexPath) // Includes refreshBarButtons().
		
		if !isEditing {
			let song = indexedLibraryItems[indexPath.row - numberOfRowsAboveIndexedLibraryItems] as! Song
			if let selectedCell = tableView.cellForRow(at: indexPath) {
				showSongActions(for: song, popoverAnchorView: selectedCell)
			}
			// This leaves the row selected while the action sheet is onscreen, which I prefer.
			// You must eventually deselect the row, and set isPresentingSongActions = false, in every possible branch from here.
		}
	}
	
}
