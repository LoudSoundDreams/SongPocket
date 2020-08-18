//
//  extension Song.swift
//  LavaRock
//
//  Created by h on 2020-08-16.
//

import CoreData
import MediaPlayer

extension Song {
	
	// There's a similar method in `extension Album`. Make this generic?
	func titleOrPlaceholder() -> String {
		if
			let storedTitle = title,
			storedTitle != ""
		{
			return storedTitle
		} else {
			return SongsTVC.unknownSongTitlePlaceholderText
		}
	}
	
	func artworkImage() -> UIImage? {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return nil
		}
		let songsQuery = MPMediaQuery.songs()
		songsQuery.addFilterPredicate(
			MPMediaPropertyPredicate(
				value: persistentID, forProperty: MPMediaItemPropertyPersistentID)
		)
		
		guard let song = songsQuery.items?[0] else {
			return nil
		}
		let mediaItemArtwork = song.artwork
		let artworkImage = mediaItemArtwork?.image(
			at: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width))
		return artworkImage
	}
	
}
