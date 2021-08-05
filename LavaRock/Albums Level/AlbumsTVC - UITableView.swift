//
//  AlbumsTVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit
import MediaPlayer

extension AlbumsTVC {
	
	// MARK: - Numbers
	
	// Identical to counterpart in SongsTVC.
	final override func tableView(
		_ tableView: UITableView,
		numberOfRowsInSection section: Int
	) -> Int {
		setOrRemoveNoItemsBackground()
		
		if sectionOfLibraryItems.isEmpty() {
			return 0
		} else {
			return sectionOfLibraryItems.items.count + numberOfRowsInSectionAboveLibraryItems
		}
	}
	
	// MARK: - Cells
	
	final override func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
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
		
		let albumTitle: String = album.titleFormattedOrPlaceholder() // Don't let this be nil.
		let releaseDateText = album.releaseDateEstimateFormatted()
		let isInPlayer = isInPlayer(libraryItemFor: indexPath)
		let isPlaying = sharedPlayer?.playbackState == .playing
		let nowPlayingIndicator = NowPlayingIndicator(
			isInPlayer: isInPlayer,
			isPlaying: isPlaying)
		
		// Make, configure, and return the cell.
		
		if let releaseDateText = releaseDateText {
			guard var cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
					as? AlbumCell
			else {
				return UITableViewCell()
			}
			cell.releaseDateLabel.text = releaseDateText
			
			let artworkMaxWidthAndHeight = cell.artworkImageView.bounds.width
			let cellImage = representativeItem?.artwork?.image(at: CGSize(width: artworkMaxWidthAndHeight, height: artworkMaxWidthAndHeight))
			cell.artworkImageView.image = cellImage
			cell.titleLabel.text = albumTitle
			cell.apply(nowPlayingIndicator)
			if albumMoverClipboard != nil {
				cell.accessoryType = .none
			}
			
			cell.accessibilityUserInputLabels = [albumTitle]
			
			return cell
			
		} else { // We couldn't determine the album's release date.
			guard var cell = tableView.dequeueReusableCell(withIdentifier: "Cell Without Release Date", for: indexPath)
					as? AlbumCellWithoutReleaseDate
			else {
				return UITableViewCell()
			}
			
			let artworkMaxWidthAndHeight = cell.artworkImageView.bounds.width
			let cellImage = representativeItem?.artwork?.image(at: CGSize(width: artworkMaxWidthAndHeight, height: artworkMaxWidthAndHeight))
			cell.artworkImageView.image = cellImage
			cell.titleLabel.text = albumTitle
			cell.apply(nowPlayingIndicator)
			if albumMoverClipboard != nil {
				cell.accessoryType = .none
			}
			
			cell.accessibilityUserInputLabels = [albumTitle]
			
			return cell
		}
	}
	
	// MARK: - Selecting
	
	final override func tableView(
		_ tableView: UITableView,
		shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath
	) -> Bool {
		if albumMoverClipboard != nil {
			return false
		} else {
			return super.tableView(
				tableView,
				shouldBeginMultipleSelectionInteractionAt: indexPath)
		}
	}
	
}
