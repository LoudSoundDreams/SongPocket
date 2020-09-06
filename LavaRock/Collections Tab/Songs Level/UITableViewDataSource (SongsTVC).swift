//
//  UITableViewDataSource (SongsTVC).swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit
import MediaPlayer

extension SongsTVC {
	
	/*
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return super.tableView(tableView, numberOfRowsInSection: section) + numberOfUneditableRowsAtTopOfSection
	}
	*/
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return super.tableView(tableView, cellForRowAt: indexPath)
		}
		
		if indexPath.row == 0 {
			
			// Get the data to put into the cell.
			let album = containerOfData as! Album
			let representativeItem = album.mpMediaItemCollection()?.representativeItem
			let cellImage = representativeItem?.artwork?.image(at: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width))
			
			// Make, configure, and return the cell.
			let albumArtworkCell = tableView.dequeueReusableCell(withIdentifier: "Album Artwork Cell") as! AlbumArtworkCell
			albumArtworkCell.artworkImageView.image = cellImage
			return albumArtworkCell
			
		} else if indexPath.row == 1 {
			
			// Get the data to put into the cell.
			let album = containerOfData as! Album
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
//			guard let song = fetchedResultsController?.object(
//				at: IndexPath(row: indexPath.row - numberOfUneditableRowsAtTopOfSection, section: indexPath.section)
//			) as? Song else {
//				return UITableViewCell()
//			}
			let song = activeLibraryItems[indexPath.row] as! Song
			let cellTrackNumberText = song.trackNumberFormattedOrPlaceholder()
			let cellTitle = song.titleFormattedOrPlaceholder()
			
			// Make, configure, and return the cell.
			if
				let cellArtist = song.artistFormatted(),
				cellArtist != (containerOfData as! Album).albumArtistFormattedOrPlaceholder()
			{
				let cell = tableView.dequeueReusableCell(withIdentifier: "Cell with Different Artist", for: indexPath) as! SongCellWithDifferentArtist
				cell.trackNumberLabel.text = cellTrackNumberText
				cell.titleLabel.text = cellTitle
				cell.artistLabel.text = cellArtist
				return cell
				
			} else { // The song's artist is not useful, or it's the same as the album artist.
				let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! SongCell
				// As of some beta of iOS 14.0, UIListContentConfiguration.valueCell() doesn't gracefully accommodate multiple lines of text.
				cell.trackNumberLabel.text = cellTrackNumberText
				cell.titleLabel.text = cellTitle
				return cell
			}
		}
	}
	
	// MARK: - Editing
	
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return indexPath.row >= numberOfUneditableRowsAtTopOfSection
	}
	
}
