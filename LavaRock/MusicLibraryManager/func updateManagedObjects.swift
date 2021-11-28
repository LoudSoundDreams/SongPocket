//
//  func updateManagedObjects.swift
//  LavaRock
//
//  Created by h on 2020-09-22.
//

import CoreData
import MediaPlayer
import OSLog

extension MusicLibraryManager {
	
	final func updateManagedObjects(
		potentiallyOutdatedSongsAndFreshMediaItems: [(Song, MPMediaItem)]
	) {
		os_signpost(.begin, log: importLog, name: "2. Update Managed Objects")
		defer {
			os_signpost(.end, log: importLog, name: "2. Update Managed Objects")
		}
		
		// Here, you can update any attributes on each Song. But it's best to not store data on each Song in the first place unless we have to, because we'll have to manually keep it up to date.
		
		
		os_signpost(.begin, log: updateLog, name: "Merge Albums with the same albumPersistentID")
		// can we do this after moveSongsToUpdatedAlbums? initializing uniqueAlbums is slow
		// ^ would that change anything?
		let uniqueAlbums_byInt64 = mergeClonedAlbumsAndReturnUniqueAlbums_byInt64(
			potentiallyOutdatedSongsAndFreshMediaItems: potentiallyOutdatedSongsAndFreshMediaItems)
		os_signpost(.end, log: updateLog, name: "Merge Albums with the same albumPersistentID")
		
		os_signpost(.begin, log: updateLog, name: "Move Songs to updated Albums")
		moveSongsToUpdatedAlbums(
			potentiallyOutdatedSongsAndFreshMediaItems: potentiallyOutdatedSongsAndFreshMediaItems,
			uniqueAlbums_byInt64: uniqueAlbums_byInt64)
		os_signpost(.end, log: updateLog, name: "Move Songs to updated Albums")
	}
	
	private func mergeClonedAlbumsAndReturnUniqueAlbums_byInt64(
		potentiallyOutdatedSongsAndFreshMediaItems: [(Song, MPMediaItem)]
	) -> [Int64: Album] {
		// I've seen an obscure bug where we had two Albums with the same albumPersistentID, probably caused by a bug in Music for Mac when I was editing metadata (once, one song appeared twice in its album).
		// We never should have ended up with two Albums with the same albumPersistentID in the first place, but this makes the importer resilient to that mistake.
		
		// To merge Albums, we'll move their Songs into one Album, then delete empty Albums.
		// Specifically, if a Song's Album isn't the uppermost one in the user's custom arrangement with that albumPersistentID, then move it to the end of that Album.
		
		os_signpost(.begin, log: updateLog, name: "Fetch all Albums")
		let allAlbums = Album.allFetched(context: context)
		os_signpost(.end, log: updateLog, name: "Fetch all Albums")
		
		os_signpost(.begin, log: updateLog, name: "Initialize uniqueAlbums")
		// We only really need a Set<Album> here, but moveSongsToUpdatedAlbums uses a [Int64: Album], so we can reuse this.
		let tuplesForAllAlbums = allAlbums.map { album in
			(album.albumPersistentID,
			album)
		}
		let uniqueAlbums_byInt64 = Dictionary(tuplesForAllAlbums) { leftAlbum, _ in
			leftAlbum // Because we fetched all Albums in sorted order.
		}
		os_signpost(.end, log: updateLog, name: "Initialize uniqueAlbums")
		
		os_signpost(.begin, log: updateLog, name: "Filter to Songs in cloned Albums")
		// Don't actually move the Songs we need to move yet, because we haven't sorted them yet.
		// Filter before sorting. Don't sort first, because that's slower.
		let unsortedSongsToMove: [Song]
		= potentiallyOutdatedSongsAndFreshMediaItems.compactMap { (song, _) in
			let currentAlbum = song.container!
			if uniqueAlbums_byInt64[currentAlbum.albumPersistentID] == currentAlbum {
				return nil
			} else {
				return song
			}
		}
		os_signpost(.end, log: updateLog, name: "Filter to Songs in cloned Albums")
		
		// Songs will very rarely make it past this point.
		
		os_signpost(.begin, log: updateLog, name: "Sort Songs in cloned Albums")
		let songsToMove = unsortedSongsToMove.sorted {
			$0.precedesInUserCustomOrder($1)
		}
		os_signpost(.end, log: updateLog, name: "Sort Songs in cloned Albums")
		
		os_signpost(.begin, log: updateLog, name: "Move Songs from cloned Albums")
		songsToMove.forEach { song in
			
			let targetAlbum = uniqueAlbums_byInt64[song.container!.albumPersistentID]!
			let newIndexOfSong = targetAlbum.contents?.count ?? 0
			song.container = targetAlbum
			song.index = Int64(newIndexOfSong)
		}
		os_signpost(.end, log: updateLog, name: "Move Songs from cloned Albums")
		
		Album.deleteAllEmpty_withoutReindex(context: context)
		
		return uniqueAlbums_byInt64
	}
	
	private func moveSongsToUpdatedAlbums(
		potentiallyOutdatedSongsAndFreshMediaItems: [(Song, MPMediaItem)],
		uniqueAlbums_byInt64: [Int64: Album]
	) {
		// If a Song's Album's albumPersistentID is no longer matches its MPMediaItem's albumPersistentID, move that Song to an existing or new Album with the up-to-date albumPersistentID.
		
		os_signpost(.begin, log: updateLog, name: "Filter to Songs moved to different Albums")
		let unsortedOutdatedTuples = potentiallyOutdatedSongsAndFreshMediaItems.filter { (song, mediaItem) in
			song.container!.albumPersistentID != Int64(bitPattern: mediaItem.albumPersistentID)
		}
		os_signpost(.end, log: updateLog, name: "Filter to Songs moved to different Albums")
		
		// Sort the existing Songs by the order they appeared in in the app.
		os_signpost(.begin, log: updateLog, name: "Sort Songs moved to different Albums")
		let outdatedTuples = unsortedOutdatedTuples.sorted { leftTuple, rightTuple in
			leftTuple.0.precedesInUserCustomOrder(rightTuple.0)
		}
		os_signpost(.end, log: updateLog, name: "Sort Songs moved to different Albums")
		
		var existingAlbums_byInt64 = uniqueAlbums_byInt64
		outdatedTuples.reversed().forEach { (song, mediaItem) in
			os_signpost(.begin, log: updateLog, name: "Move one Song to its up-to-date Album")
			defer {
				os_signpost(.end, log: updateLog, name: "Move one Song to its up-to-date Album")
			}
			
			// Get this Song's fresh albumPersistentID.
			os_signpost(.begin, log: updateLog, name: "Get one Song's fresh albumPersistentID")
			let newAlbumPersistentID_asInt64 = Int64(bitPattern: mediaItem.albumPersistentID)
			os_signpost(.end, log: updateLog, name: "Get one Song's fresh albumPersistentID")
			
			// If this Song's albumPersistentID has stayed the same, move on to the next one.
			guard
				newAlbumPersistentID_asInt64 != song.container!.albumPersistentID
			else { return }
			
			// This Song's albumPersistentID has changed.
			// If we already have a matching Album to move the Song to …
			if let existingAlbum = existingAlbums_byInt64[newAlbumPersistentID_asInt64] {
				// … then move the Song to that Album.
				os_signpost(.begin, log: updateLog, name: "Move a Song to an existing Album")
				existingAlbum.songs(sorted: false).forEach { $0.index += 1 }
				
				song.index = 0
				song.container = existingAlbum
				os_signpost(.end, log: updateLog, name: "Move a Song to an existing Album")
			} else {
				// Otherwise, create the Album to move the Song to …
				os_signpost(.begin, log: updateLog, name: "Move a Song to a new Album")
				let existingCollection = song.container!.container!
				let newAlbum = Album(
					atBeginningOf: existingCollection,
					for: mediaItem,
					context: context)
				
				// … and then move the Song to that Album.
				song.index = 0
				song.container = newAlbum
				
				// Make a note of the new Album.
				existingAlbums_byInt64[newAlbumPersistentID_asInt64] = newAlbum
				
				os_signpost(.end, log: updateLog, name: "Move a Song to a new Album")
			}
		}
		
		// We'll delete empty Albums and Collections later.
	}
	
}
