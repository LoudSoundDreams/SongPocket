// 2020-09-22

import CoreData

extension MusicRepo {
	func updateLibraryItems(existingAndFresh: [(Song, SongInfo)]) {
		// Merge `Album`s with the same `albumPersistentID`
		let canonicalAlbums: [AlbumID: Album] = mergeClonedAlbumsAndReturnCanonical(existingAndFresh: existingAndFresh)
		
		// Move `Song`s to updated `Album`s
		moveSongsToUpdatedAlbums(existingAndFresh: existingAndFresh, canonicalAlbums: canonicalAlbums)
	}
	
	private func mergeClonedAlbumsAndReturnCanonical(
		existingAndFresh: [(Song, SongInfo)]
	) -> [AlbumID: Album] {
		// I’ve seen an obscure bug where we had two `Album`s with the same `albumPersistentID`, probably caused by a bug in Apple Music for Mac when I was editing metadata. (Once, one song appeared twice in its album.)
		// We never should have had two `Album`s with the same `albumPersistentID`, but this code makes our database resilient to that problem.
		
		// To merge `Album`s with the same `albumPersistentID`, we’ll move their `Song`s into one `Album`, then delete empty `Album`s.
		// The one `Album` we’ll keep is the uppermost in the user’s custom order.
		let topmostUniqueAlbums: [AlbumID: Album] = {
			let allAlbums = Album.allFetched(sorted: true, context: context)
			let tuplesForAllAlbums = allAlbums.map { album in
				(album.albumPersistentID, album)
			}
			return Dictionary(tuplesForAllAlbums, uniquingKeysWith: { (leftAlbum, _) in leftAlbum })
		}()
		
		// Filter to `Song`s in cloned `Album`s
		// Don’t actually move any `Song`s, because we haven’t sorted them yet.
		let unsortedToMove: [Song] = existingAndFresh.compactMap { (song, _) in
			let album = song.container!
			let canonical = topmostUniqueAlbums[album.albumPersistentID]!
			guard canonical.objectID != album.objectID else { return nil }
			return song
		}
		
		// `Song`s will very rarely make it past this point.
		
		let toMove = unsortedToMove.sorted { $0.precedesInUserCustomOrder($1) }
		toMove.forEach { song in
			let destination = topmostUniqueAlbums[song.container!.albumPersistentID]!
			song.index = Int64(destination.contents?.count ?? 0)
			song.container = destination
		}
		
		context.unsafe_DeleteEmptyAlbums_WithoutReindexOrCascade()
		
		return topmostUniqueAlbums
	}
	
	private func moveSongsToUpdatedAlbums(
		existingAndFresh: [(Song, SongInfo)],
		canonicalAlbums: [AlbumID: Album]
	) {
		// If a `Song`’s `Album.albumPersistentID` no longer matches the `Song`’s `SongInfo.albumID`, move that `Song` to an existing or new `Album` with the up-to-date `albumPersistentID`.
		
		let toUpdate: [(Song, SongInfo)] = {
			// Filter to `Song`s moved to different `Album`s
			let unsortedOutdated = existingAndFresh.filter { (song, info) in
				info.albumID != song.container!.albumPersistentID
			}
			// Sort by the order the user arranged the `Song`s in the app.
			return unsortedOutdated.sorted { leftTuple, rightTuple in
				leftTuple.0.precedesInUserCustomOrder(rightTuple.0)
			}
		}()
		var existingAlbums = canonicalAlbums
		toUpdate.reversed().forEach { (song, info) in
			// This `Song`’s `albumPersistentID` has changed. Move it to its up-to-date `Album`.
			let newAlbumID = info.albumID
			// If we already have a matching `Album` to move the `Song` to…
			if let existingAlbum = existingAlbums[newAlbumID] {
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
				existingAlbums[newAlbumID] = newAlbum
			}
		}
	}
}
