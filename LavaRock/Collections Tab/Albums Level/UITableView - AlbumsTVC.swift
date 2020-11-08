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
			return super.tableView(tableView, cellForRowAt: indexPath)
		}
		
		// Get the data to put into the cell.
		
		let album = indexedLibraryItems[indexPath.row - numberOfRowsAboveIndexedLibraryItems] as! Album
		let representativeItem = album.mpMediaItemCollection()?.representativeItem
		
//		print(indexPath)
//		print(album.titleFormattedOrPlaceholder())
		
		let cellTitle = album.titleFormattedOrPlaceholder()
		let cellSubtitle = album.releaseDateEstimateFormatted()
		
		// Make, configure, and return the cell.
		if let cellSubtitle = cellSubtitle {
			let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! AlbumCell
			cell.releaseDateLabel.text = cellSubtitle
			
			let artworkMaxWidthAndHeight = cell.artworkImageView.bounds.width
			let cellImage = representativeItem?.artwork?.image(at: CGSize(width: artworkMaxWidthAndHeight, height: artworkMaxWidthAndHeight))
			cell.artworkImageView.image = cellImage
			cell.titleLabel.text = cellTitle
			
			
//			if PlayerControllerManager.shared.currentSong?.container == album {
//				if playerController?.playbackState == .playing {
//					cell.nowPlayingIndicatorImageView.image = UIImage(systemName: "speaker.wave.2.fill")
//				} else {
//					cell.nowPlayingIndicatorImageView.image = UIImage(systemName: "speaker.fill")
//				}
//			} else {
				cell.nowPlayingIndicatorImageView.image = nil
//			}
			
			
			if albumMoverClipboard != nil {
				cell.accessoryType = .none
			}
			return cell
			
		} else { // We couldn't determine the album's release date.
			let cell = tableView.dequeueReusableCell(withIdentifier: "Cell Without Release Date", for: indexPath) as! AlbumCellWithoutReleaseDate
			
			let artworkMaxWidthAndHeight = cell.artworkImageView.bounds.width
			let cellImage = representativeItem?.artwork?.image(at: CGSize(width: artworkMaxWidthAndHeight, height: artworkMaxWidthAndHeight))
			cell.artworkImageView.image = cellImage
			cell.titleLabel.text = cellTitle
			
			
//			if PlayerControllerManager.shared.currentSong?.container == album {
//				if playerController?.playbackState == .playing {
//					cell.nowPlayingIndicatorImageView.image = UIImage(systemName: "speaker.wave.2.fill")
//				} else {
//					cell.nowPlayingIndicatorImageView.image = UIImage(systemName: "speaker.fill")
//				}
//			} else {
				cell.nowPlayingIndicatorImageView.image = nil
//			}
			
			
			if albumMoverClipboard != nil {
				cell.accessoryType = .none
			}
			return cell
		}
		
	}
	
}
