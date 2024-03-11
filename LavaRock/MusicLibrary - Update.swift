//
//  MusicLibrary - Merge, Update.swift
//  LavaRock
//
//  Created by h on 2020-09-22.
//

import CoreData

extension MusicLibrary {
	func updateLibraryItems(
		potentiallyOutdatedSongsAndFreshInfos: [(Song, SongInfo)]
	) {
		// Merge `Album`s with the same `albumPersistentID`
		let uniqueAlbumsByID = mergeClonedAlbumsAndReturnUniqueAlbumsByID(
			potentiallyOutdatedSongsAndFreshInfos: potentiallyOutdatedSongsAndFreshInfos)
		
		// Move `Song`s to updated `Album`s
		moveSongsToUpdatedAlbums(
			potentiallyOutdatedSongsAndFreshInfos: potentiallyOutdatedSongsAndFreshInfos,
			uniqueAlbumsByID: uniqueAlbumsByID)
	}
	
	private func mergeClonedAlbumsAndReturnUniqueAlbumsByID(
		potentiallyOutdatedSongsAndFreshInfos: [(Song, SongInfo)]
	) -> [AlbumID: Album] {
		// I’ve seen an obscure bug where we had two `Album`s with the same `albumPersistentID`, probably caused by a bug in Apple Music for Mac when I was editing metadata. (Once, one song appeared twice in its album.)
		// We never should have ended up with two `Album`s with the same `albumPersistentID` in the first place, but this makes the merger resilient to that mistake.
		
		// To merge `Album`s, we’ll move their `Song`s into one `Album`, then delete empty `Album`s.
		// Specifically, if a `Song`’s `Album` isn’t the uppermost one in the user’s custom order with that `albumPersistentID`, then move it to the end of that `Album`.
		
		let allAlbums = Album.allFetched(sorted: true, inCollection: nil, context: context)
		
		// We only really need a `Set<Album>` here, but `moveSongsToUpdatedAlbums` needs a `[AlbumID: Album]`, so we can reuse this.
		let uniqueAlbumsByID: Dictionary<AlbumID, Album> = {
			let tuplesForAllAlbums = allAlbums.map { album in
				(album.albumPersistentID, album)
			}
			return Dictionary(tuplesForAllAlbums, uniquingKeysWith: { (leftAlbum, _) in leftAlbum })
		}()
		
		// Filter to `Song`s in cloned `Album`s
		// Don’t actually move the `Song`s we need to move yet, because we haven’t sorted them yet.
		// Filter before sorting. It’s faster.
		let unsortedSongsToMove: [Song]
		= potentiallyOutdatedSongsAndFreshInfos.compactMap { (song, _) in
			let potentiallyClonedAlbum = song.container!
			let canonicalAlbum = uniqueAlbumsByID[potentiallyClonedAlbum.albumPersistentID]
			if potentiallyClonedAlbum.objectID == canonicalAlbum?.objectID {
				return nil
			} else {
				return song
			}
		}
		
		// `Song`s will very rarely make it past this point.
		
		// Sort `Song`s in cloned `Album`s
		let songsToMove = unsortedSongsToMove.sorted {
			$0.precedesInUserCustomOrder($1)
		}
		
		// Move `Song`s from cloned `Album`s
		songsToMove.forEach { song in
			let targetAlbum = uniqueAlbumsByID[song.container!.albumPersistentID]!
			let newIndexOfSong = targetAlbum.contents?.count ?? 0
			song.container = targetAlbum
			song.index = Int64(newIndexOfSong)
		}
		
		context.unsafe_DeleteEmptyAlbums_WithoutReindexOrCascade()
		
		return uniqueAlbumsByID
	}
	
	private func moveSongsToUpdatedAlbums(
		potentiallyOutdatedSongsAndFreshInfos: [(Song, SongInfo)],
		uniqueAlbumsByID: [AlbumID: Album]
	) {
		// If a `Song`’s `Album.albumPersistentID` no longer matches the `Song`’s `SongInfo.albumID`, move that `Song` to an existing or new `Album` with the up-to-date `albumPersistentID`.
		
		// Filter to `Song`s moved to different `Album`s
		let unsortedOutdatedTuples = potentiallyOutdatedSongsAndFreshInfos.filter { (song, info) in
			song.container!.albumPersistentID != info.albumID
		}
		
		// Sort the existing `Song`s by the order they appeared in in the app.
		let outdatedTuples = unsortedOutdatedTuples.sorted { leftTuple, rightTuple in
			leftTuple.0.precedesInUserCustomOrder(rightTuple.0)
		}
		
		var existingAlbumsByID = uniqueAlbumsByID
		outdatedTuples.reversed().forEach { (song, info) in
			// Move one `Song` to its up-to-date `Album`
			
			// Get this `Song`’s fresh `albumPersistentID`.
			let newAlbumID = info.albumID
			
			// If this Song’s `albumPersistentID` has stayed the same, move on to the next one.
			guard
				newAlbumID != song.container!.albumPersistentID
			else { return }
			
			// This `Song`’s `albumPersistentID` has changed.
			// If we already have a matching `Album` to move the `Song` to…
			if let existingAlbum = existingAlbumsByID[newAlbumID] {
				// …then move the `Song` to that `Album`.
				existingAlbum.songs(sorted: false).forEach { $0.index += 1 }
				
				song.index = 0
				song.container = existingAlbum
			} else {
				// Otherwise, create the `Album` to move the `Song` to…
				let existingCollection = song.container!.container!
				let newAlbum = Album(
					atBeginningOf: existingCollection,
					albumID: info.albumID,
					context: context)
				
				// …and then move the `Song` to that `Album`.
				song.index = 0
				song.container = newAlbum
				
				// Make a note of the new `Album`.
				existingAlbumsByID[newAlbumID] = newAlbum
			}
		}
	}
}
