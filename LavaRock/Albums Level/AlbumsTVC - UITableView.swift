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
		
		return viewModel.numberOfRows(inSection: section)
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
		guard let album = viewModel.item(at: indexPath) as? Album else {
			return UITableViewCell()
		}
		
		// Title
		let albumTitle: String = album.titleFormattedOrPlaceholder() // Don't let this be nil.
		
		// Release date
		let releaseDateString = album.releaseDateEstimateFormatted()
		
		// "Now playing" indicator
		let isInPlayer = isInPlayer(libraryItemFor: indexPath)
		let isPlaying = sharedPlayer?.playbackState == .playing
		let nowPlayingIndicator = NowPlayingIndicator(
			isInPlayer: isInPlayer,
			isPlaying: isPlaying)
		
		// Make, configure, and return the cell.
		let artwork = album.mpMediaItemCollection()?.representativeItem?.artwork // Can be nil
		if let releaseDateString = releaseDateString {
			guard var cell = tableView.dequeueReusableCell(
				withIdentifier: Self.libraryItemCellReuseIdentifier,
				for: indexPath) as? AlbumCell
			else {
				return UITableViewCell()
			}
			
			let artworkMaxWidthAndHeight = cell.artworkImageView.bounds.width
			cell.artworkImageView.image = artwork?.image(at: CGSize(
				width: artworkMaxWidthAndHeight,
				height: artworkMaxWidthAndHeight))
			cell.titleLabel.text = albumTitle
			cell.apply(nowPlayingIndicator)
			if albumMoverClipboard != nil {
				cell.accessoryType = .none
			}
			
			cell.releaseDateLabel.text = releaseDateString
			
			cell.accessibilityUserInputLabels = [albumTitle]
			
			return cell
			
		} else { // We couldn't determine the album's release date.
			guard var cell = tableView.dequeueReusableCell(
				withIdentifier: "Cell Without Release Date",
				for: indexPath) as? AlbumCellWithoutReleaseDate
			else {
				return UITableViewCell()
			}
			
			let artworkMaxWidthAndHeight = cell.artworkImageView.bounds.width
			cell.artworkImageView.image = artwork?.image(at: CGSize(
				width: artworkMaxWidthAndHeight,
				height: artworkMaxWidthAndHeight))
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
