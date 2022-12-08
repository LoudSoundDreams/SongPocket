//
//  MPMediaItem + SongMetadatum.swift
//  LavaRock
//
//  Created by h on 2022-06-30.
//

import MediaPlayer
import UIKit
import OSLog

extension MPMediaItem: SongMetadatum {
	final var albumID: AlbumID { AlbumID(bitPattern: albumPersistentID) }
	final var songID: SongID { SongID(bitPattern: persistentID) }
	
	// Media Player reports unknown values as …
	
	final var albumArtistOnDisk: String? { albumArtist } // … `nil`, as of iOS 14.7 developer beta 5.
	final var albumTitleOnDisk: String? { albumTitle } // … `""`, as of iOS 14.7 developer beta 5.
	
	final var discCountOnDisk: Int { discCount } // … `0`, as of iOS 15.0 RC.
	final var discNumberOnDisk: Int { discNumber } // … `1`, as of iOS 14.7 developer beta 5.
	final var trackNumberOnDisk: Int { albumTrackNumber }
	static let unknownTrackNumber = 0 // As of iOS 14.7 developer beta 5.
	
	final var titleOnDisk: String? { title } // … we don’t know, because Music for Mac as of version 1.1.5.74 doesn’t allow blank song titles. But that means we shouldn’t need to move unknown song titles to the end.
	final var artistOnDisk: String? { artist }
	
	final var dateAddedOnDisk: Date { dateAdded }
	final var releaseDateOnDisk: Date? { releaseDate }
	
	final func coverArt(largerThanOrEqualToSizeInPoints sizeInPoints: CGSize) -> UIImage? {
		let signposter = OSSignposter()
		let state = signposter.beginInterval("Draw cover art")
		defer {
			signposter.endInterval("Draw cover art", state)
		}
		return artwork?.image(at: sizeInPoints)
	}
}
