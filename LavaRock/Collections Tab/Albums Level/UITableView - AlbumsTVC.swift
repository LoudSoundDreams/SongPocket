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
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return UITableViewCell()
		}
		
		// Get the data to put into the cell.
		
		let album = indexedLibraryItems[indexPath.row - numberOfRowsAboveIndexedLibraryItems] as! Album
		let representativeItem = album.mpMediaItemCollection()?.representativeItem
		
		let cellTitle = album.titleFormattedOrPlaceholder()
		let cellSubtitle = album.releaseDateEstimateFormatted()
		let isNowPlayingAlbum = isNowPlayingItem(at: indexPath)
		let cellNowPlayingIndicator = nowPlayingIndicator(isNowPlayingItem: isNowPlayingAlbum)
		
		// Make, configure, and return the cell.
		
		if let cellSubtitle = cellSubtitle {
			var cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! AlbumCell
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
			var cell = tableView.dequeueReusableCell(withIdentifier: "Cell Without Release Date", for: indexPath) as! AlbumCellWithoutReleaseDate
			
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
