//
//  MPMediaItem.swift
//  LavaRock
//
//  Created by h on 2021-07-10.
//

import MediaPlayer

extension MPMediaItem: SongFile {
	var albumFolderID: AlbumFolderID { AlbumFolderID(bitPattern: albumPersistentID) }
	var fileID: SongFileID { SongFileID(bitPattern: persistentID) }
	
	// Media Player reports unknown values as …
	var albumArtistOnDisk: String? { albumArtist } // … `nil`, as of iOS 14.7 developer beta 5.
	var albumTitleOnDisk: String? { albumTitle } // … `""`, as of iOS 14.7 developer beta 5.
	var discCountOnDisk: Int { discCount } // … `0`, as of iOS 15.0 RC.
	var discNumberOnDisk: Int { discNumber } // … `1`, as of iOS 14.7 developer beta 5.
	var trackNumberOnDisk: Int { albumTrackNumber } // … `0`, as of iOS 14.7 developer beta 5.
	var titleOnDisk: String? { title } // … we don't know, because Music for Mac as of version 1.1.5.74 doesn't allow blank song titles. But that means we shouldn't need to move unknown song titles to the end.
	var artistOnDisk: String? { artist }
	var releaseDateOnDisk: Date? { releaseDate }
	var dateAddedOnDisk: Date { dateAdded }
	
	func artworkImage(at size: CGSize) -> UIImage? {
		return artwork?.image(at: size)
	}
}
