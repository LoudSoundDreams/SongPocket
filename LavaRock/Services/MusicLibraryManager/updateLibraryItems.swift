//
//  updateLibraryItems.swift
//  LavaRock
//
//  Created by h on 2020-09-22.
//

import CoreData
import OSLog

extension MusicLibraryManager {
	
	final func updateLibraryItems(
		potentiallyOutdatedSongsAndFreshSongFiles: [(Song, SongFile)]
	) {
		os_signpost(.begin, log: .merge, name: "2. Update library items")
		defer {
			os_signpost(.end, log: .merge, name: "2. Update library items")
		}
		
		os_signpost(.begin, log: .update, name: "Merge Albums with the same albumPersistentID")
		let uniqueAlbumsByID = mergeClonedAlbumsAndReturnUniqueAlbumsByID(
			potentiallyOutdatedSongsAndFreshSongFiles: potentiallyOutdatedSongsAndFreshSongFiles)
		os_signpost(.end, log: .update, name: "Merge Albums with the same albumPersistentID")
		
		os_signpost(.begin, log: .update, name: "Move Songs to updated Albums")
		moveSongsToUpdatedAlbums(
			potentiallyOutdatedSongsAndFreshSongFiles: potentiallyOutdatedSongsAndFreshSongFiles,
			uniqueAlbumsByID: uniqueAlbumsByID)
		os_signpost(.end, log: .update, name: "Move Songs to updated Albums")
	}
	
	private func mergeClonedAlbumsAndReturnUniqueAlbumsByID(
		potentiallyOutdatedSongsAndFreshSongFiles: [(Song, SongFile)]
	) -> [AlbumFolderID: Album] {
		// I've seen an obscure bug where we had two `Album`s with the same `albumPersistentID`, probably caused by a bug in Music for Mac when I was editing metadata. (Once, one song appeared twice in its album.)
		// We never should have ended up with two `Album`s with the same `albumPersistentID` in the first place, but this makes the merger resilient to that mistake.
		
		// To merge `Album`s, we'll move their `Song`s into one `Album`, then delete empty `Album`s.
		// Specifically, if a `Song`'s `Album` isn't the uppermost one in the user's custom arrangement with that `albumPersistentID`, then move it to the end of that `Album`.
		
		os_signpost(.begin, log: .update, name: "Fetch all Albums")
		let allAlbums = Album.allFetched(ordered: true, via: context)
		os_signpost(.end, log: .update, name: "Fetch all Albums")
		
		os_signpost(.begin, log: .update, name: "Initialize uniqueAlbums")
		// We only really need a `Set<Album>` here, but `moveSongsToUpdatedAlbums` needs a `[AlbumFolderID: Album]`, so we can reuse this.
		let uniqueAlbumsByID: Dictionary<AlbumFolderID, Album> = {
			let tuplesForAllAlbums = allAlbums.map { album in
				(album.albumPersistentID, album)
			}
			return Dictionary(tuplesForAllAlbums, uniquingKeysWith: { (leftAlbum, _) in leftAlbum })
		}()
		os_signpost(.end, log: .update, name: "Initialize uniqueAlbums")
		
		os_signpost(.begin, log: .update, name: "Filter to Songs in cloned Albums")
		// Don't actually move the Songs we need to move yet, because we haven't sorted them yet.
		// Filter before sorting. Don't sort first, because that's slower.
		let unsortedSongsToMove: [Song]
		= potentiallyOutdatedSongsAndFreshSongFiles.compactMap { (song, _) in
			let potentiallyClonedAlbum = song.container!
			let canonicalAlbum = uniqueAlbumsByID[potentiallyClonedAlbum.albumPersistentID]
			if potentiallyClonedAlbum.objectID == canonicalAlbum?.objectID {
				return nil
			} else {
				return song
			}
		}
		os_signpost(.end, log: .update, name: "Filter to Songs in cloned Albums")
		
		// Songs will very rarely make it past this point.
		
		os_signpost(.begin, log: .update, name: "Sort Songs in cloned Albums")
		let songsToMove = unsortedSongsToMove.sorted {
			$0.precedesInUserCustomOrder($1)
		}
		os_signpost(.end, log: .update, name: "Sort Songs in cloned Albums")
		
		os_signpost(.begin, log: .update, name: "Move Songs from cloned Albums")
		songsToMove.forEach { song in
			let targetAlbum = uniqueAlbumsByID[song.container!.albumPersistentID]!
			let newIndexOfSong = targetAlbum.contents?.count ?? 0
			song.container = targetAlbum
			song.index = Int64(newIndexOfSong)
		}
		os_signpost(.end, log: .update, name: "Move Songs from cloned Albums")
		
		Album.deleteAllEmpty_withoutReindexOrCascade(via: context)
		
		return uniqueAlbumsByID
	}
	
	private func moveSongsToUpdatedAlbums(
		potentiallyOutdatedSongsAndFreshSongFiles: [(Song, SongFile)],
		uniqueAlbumsByID: [AlbumFolderID: Album]
	) {
		// If a `Song`’s `Album.albumPersistentID` no longer matches the `Song`’s `SongFile.albumFolderID`, move that `Song` to an existing or new `Album` with the up-to-date `albumPersistentID`.
		
		os_signpost(.begin, log: .update, name: "Filter to Songs moved to different Albums")
		let unsortedOutdatedTuples = potentiallyOutdatedSongsAndFreshSongFiles.filter { (song, songFile) in
			song.container!.albumPersistentID != songFile.albumFolderID
		}
		os_signpost(.end, log: .update, name: "Filter to Songs moved to different Albums")
		
		// Sort the existing Songs by the order they appeared in in the app.
		os_signpost(.begin, log: .update, name: "Sort Songs moved to different Albums")
		let outdatedTuples = unsortedOutdatedTuples.sorted { leftTuple, rightTuple in
			leftTuple.0.precedesInUserCustomOrder(rightTuple.0)
		}
		os_signpost(.end, log: .update, name: "Sort Songs moved to different Albums")
		
		var existingAlbumsByID = uniqueAlbumsByID
		outdatedTuples.reversed().forEach { (song, songFile) in
			os_signpost(.begin, log: .update, name: "Move one Song to its up-to-date Album")
			defer {
				os_signpost(.end, log: .update, name: "Move one Song to its up-to-date Album")
			}
			
			// Get this Song's fresh albumPersistentID.
			os_signpost(.begin, log: .update, name: "Get one Song's fresh albumPersistentID")
			let newAlbumFolderID = songFile.albumFolderID
			os_signpost(.end, log: .update, name: "Get one Song's fresh albumPersistentID")
			
			// If this Song's albumPersistentID has stayed the same, move on to the next one.
			guard
				newAlbumFolderID != song.container!.albumPersistentID
			else { return }
			
			// This Song's albumPersistentID has changed.
			// If we already have a matching Album to move the Song to …
			if let existingAlbum = existingAlbumsByID[newAlbumFolderID] {
				// … then move the Song to that Album.
				os_signpost(.begin, log: .update, name: "Move a Song to an existing Album")
				existingAlbum.songs(sorted: false).forEach { $0.index += 1 }
				
				song.index = 0
				song.container = existingAlbum
				os_signpost(.end, log: .update, name: "Move a Song to an existing Album")
			} else {
				// Otherwise, create the Album to move the Song to …
				os_signpost(.begin, log: .update, name: "Move a Song to a new Album")
				let existingCollection = song.container!.container!
				let newAlbum = Album(
					atBeginningOf: existingCollection,
					albumFolderID: songFile.albumFolderID,
					context: context)
				
				// … and then move the Song to that Album.
				song.index = 0
				song.container = newAlbum
				
				// Make a note of the new Album.
				existingAlbumsByID[newAlbumFolderID] = newAlbum
				
				os_signpost(.end, log: .update, name: "Move a Song to a new Album")
			}
		}
		
		// We'll delete empty Albums and Collections later.
	}
	
}
