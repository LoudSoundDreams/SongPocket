//
//  UITableView - AlbumsTVC.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit
import MediaPlayer

extension AlbumsTVC {
	
	// MARK: - Cells
	
	final override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return UITableViewCell()
		}
		
		return albumCell(forRowAt: indexPath)
	}
	
	private func albumCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		// Get the data to put into the cell.
		
		guard let album = libraryItem(for: indexPath) as? Album else {
			return UITableViewCell()
		}
		let representativeItem = album.mpMediaItemCollection()?.representativeItem
		
		let cellTitle = album.titleFormattedOrPlaceholder()
		let cellSubtitle = album.releaseDateEstimateFormatted()
		let isNowPlayingAlbum = isItemNowPlaying(at: indexPath)
		let cellNowPlayingIndicator = PlayerControllerManager.nowPlayingIndicator(
			isItemNowPlaying: isNowPlayingAlbum)
		
		// Make, configure, and return the cell.
		
		if let cellSubtitle = cellSubtitle {
			guard var cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as? AlbumCell else {
				return UITableViewCell()
			}
			cell.releaseDateLabel.text = cellSubtitle
			
			let artworkMaxWidthAndHeight = cell.artworkImageView.bounds.width
			let cellImage = representativeItem?.artwork?.image(at: CGSize(width: artworkMaxWidthAndHeight, height: artworkMaxWidthAndHeight))
			cell.artworkImageView.image = cellImage
			cell.titleLabel.text = cellTitle
			cell.applyNowPlayingIndicator(cellNowPlayingIndicator)
			if albumMoverClipboard != nil {
				cell.accessoryType = .none
			}
			
			cell.accessibilityUserInputLabels = [cellTitle]
			
			return cell
			
		} else { // We couldn't determine the album's release date.
			guard var cell = tableView.dequeueReusableCell(withIdentifier: "Cell Without Release Date", for: indexPath) as? AlbumCellWithoutReleaseDate else {
				return UITableViewCell()
			}
			
			let artworkMaxWidthAndHeight = cell.artworkImageView.bounds.width
			let cellImage = representativeItem?.artwork?.image(at: CGSize(width: artworkMaxWidthAndHeight, height: artworkMaxWidthAndHeight))
			cell.artworkImageView.image = cellImage
			cell.titleLabel.text = cellTitle
			cell.applyNowPlayingIndicator(cellNowPlayingIndicator)
			if albumMoverClipboard != nil {
				cell.accessoryType = .none
			}
			
			cell.accessibilityUserInputLabels = [cellTitle]
			
			return cell
		}
	}
	
}
