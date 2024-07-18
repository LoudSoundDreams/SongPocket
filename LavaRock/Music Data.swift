// 2020-08-10

import CoreData
@preconcurrency import MusicKit
import MediaPlayer
import SwiftUI

@MainActor @Observable final class Crate {
	private(set) var musicKitSections: [MusicItemID: MusicLibrarySection<MusicKit.Album, MusicKit.Song>] = [:]
	
	private init() {}
	@ObservationIgnored private let context = Database.viewContext
}
extension Crate {
	static let shared = Crate()
	func observeMediaPlayerLibrary() {
		let library = MPMediaLibrary.default()
		library.beginGeneratingLibraryChangeNotifications()
		NotificationCenter.default.addObserverOnce(self, selector: #selector(mergeChanges), name: .MPMediaLibraryDidChange, object: library)
		mergeChanges()
	}
	static let mergedChanges = Notification.Name("LRMusicLibraryMerged")
	func musicKitSection(_ albumID: AlbumID) -> MusicLibrarySection<MusicKit.Album, MusicKit.Song>? {
		return musicKitSections[MusicItemID(String(albumID))]
	}
	static func openAppleMusic() {
		guard let musicLibraryURL = URL(string: "music://") else { return }
		UIApplication.shared.open(musicLibraryURL)
	}
}

// MARK: - Private

extension Crate {
	@objc private func mergeChanges() {
#if targetEnvironment(simulator)
		context.performAndWait {
			mergeChangesToMatch(freshInAnyOrder: Array(Sim_SongInfo.everyInfo.values))
		}
#else
		if let freshMediaItems = MPMediaQuery.songs().items {
			context.performAndWait {
				mergeChangesToMatch(freshInAnyOrder: freshMediaItems)
			}
		}
		
		Task {
			let fresh: [MusicItemID: MusicLibrarySection<MusicKit.Album, MusicKit.Song>] = await {
				let request = MusicLibrarySectionedRequest<MusicKit.Album, MusicKit.Song>()
				guard let response = try? await request.response() else { return [:] }
				
				let tuples = response.sections.map { section in (section.id, section) }
				return Dictionary(uniqueKeysWithValues: tuples)
			}()
			
			var union = musicKitSections
			fresh.forEach { (key, value) in union[key] = value }
			withAnimation { // Spooky action at a distance
				musicKitSections = union // Show new data immediately…
			}
			try? await Task.sleep(for: .seconds(3)) // …but don’t hide deleted data before animating it away anyway.
			
			withAnimation {
				musicKitSections = fresh
			}
		}
#endif
	}
	private func mergeChangesToMatch(freshInAnyOrder: [SongInfo]) {
		// Find out which existing `Song`s we need to delete, and which we need to potentially update.
		// Meanwhile, isolate the `SongInfo`s that we don’t have `Song`s for. We’ll create new `Song`s for them.
		let toUpdate: [(existing: Song, fresh: SongInfo)]
		let toDelete: [Song]
		let toCreate: [SongInfo]
		do {
			var updates: [(Song, SongInfo)] = []
			var deletes: [Song] = []
			
			var freshInfos: [SongID: SongInfo] = {
				let tuples = freshInAnyOrder.map { info in (info.songID, info) }
				return Dictionary(uniqueKeysWithValues: tuples)
			}()
			let existingSongs: [Song] = context.fetchPlease(Song.fetchRequest()) // Not sorted
			existingSongs.forEach { existingSong in
				let songID = existingSong.persistentID
				if let freshInfo = freshInfos[songID] {
					// We have an existing `Song` for this `SongInfo`. We might need to update the `Song`.
					updates.append((existingSong, freshInfo)) // We’ll sort these later.
					
					freshInfos[songID] = nil
				} else {
					// This `Song` no longer corresponds to any `SongInfo` in the library. We’ll delete it.
					deletes.append(existingSong)
				}
			}
			// `freshInfos` now holds the `SongInfo`s that we don’t have `Song`s for.
			
			toUpdate = updates
			toDelete = deletes
			toCreate = freshInfos.map { $0.value } // We’ll sort these later.
		}
		
		// Update before creating and deleting, so that we can easily put new `Song`s above modified `Song`s.
		// This also deletes all but one `Album` with any given `albumPersistentID`.
		// This might create `Album`s, but not `Collection`s or `Song`s.
		// This might delete `Album`s, but not `Collection`s or `Song`s.
		// This also might leave behind empty `Album`s. We don’t delete those here, so that if the user also added other `Song`s to those `Album`s, we can keep those `Album`s in the same place, instead of re-adding them to the top.
		updateLibraryItems(existingAndFresh: toUpdate)
		
		// Create before deleting, because deleting also cleans up empty `Album`s and `Collection`s, which we shouldn’t do yet (see above).
		// This might create new `Album`s, and if it does, it might create new `Collection`s.
		createLibraryItems(newInfos: toCreate)
		cleanUpLibraryItems(songsToDelete: toDelete, allInfos: freshInAnyOrder)
		
		context.savePlease()
		
		Task { NotificationCenter.default.post(name: Self.mergedChanges, object: nil) }
	}
	
	// MARK: - Update
	
	private func updateLibraryItems(existingAndFresh: [(Song, SongInfo)]) {
		// Merge `Album`s with the same `albumPersistentID`
		let canonicalAlbums: [AlbumID: Album] = mergeClonedAlbumsAndReturnCanonical(existingAndFresh: existingAndFresh)
		
		// Move `Song`s to updated `Album`s
		moveSongsToUpdatedAlbums(
			existingAndFresh: existingAndFresh.map { (song, info) in (song, info.albumID) },
			canonicalAlbums: canonicalAlbums)
	}
	
	private func mergeClonedAlbumsAndReturnCanonical(
		existingAndFresh: [(Song, SongInfo)]
	) -> [AlbumID: Album] {
		// I’ve seen an obscure bug where we had two `Album`s with the same `albumPersistentID`, probably caused by a bug in Apple Music for Mac when I was editing metadata. (Once, one song appeared twice in its album.)
		// We never should have had two `Album`s with the same `albumPersistentID`, but this code makes our database resilient to that problem.
		
		// To merge `Album`s with the same `albumPersistentID`, we’ll move their `Song`s into one `Album`, then delete empty `Album`s.
		// The one `Album` we’ll keep is the uppermost in the user’s custom order.
		let topmostUniqueAlbums: [AlbumID: Album] = {
			let allAlbums = context.fetchPlease(Album.fetchRequest_sorted())
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
		existingAndFresh: [(Song, AlbumID)],
		canonicalAlbums: [AlbumID: Album]
	) {
		// If a `Song`’s `Album.albumPersistentID` no longer matches the `Song`’s `SongInfo.albumID`, move that `Song` to an existing or new `Album` with the up-to-date `albumPersistentID`.
		let toUpdate: [(Song, AlbumID)] = {
			// Filter to `Song`s moved to different `Album`s
			let unsortedOutdated = existingAndFresh.filter { (song, albumID) in
				albumID != song.container!.albumPersistentID
			}
			// Sort by the order the user arranged the `Song`s in the app.
			return unsortedOutdated.sorted { leftTuple, rightTuple in
				leftTuple.0.precedesInUserCustomOrder(rightTuple.0)
			}
		}()
		var existingAlbums = canonicalAlbums
		toUpdate.reversed().forEach { (song, freshAlbumID) in
			// This `Song`’s `albumPersistentID` has changed. Move it to its up-to-date `Album`.
			// If we already have a matching `Album` to move the `Song` to…
			if let existingAlbum = existingAlbums[freshAlbumID] {
				// …then move the `Song` to that `Album`.
				existingAlbum.songs(sorted: false).forEach { $0.index += 1 }
				
				song.index = 0
				song.container = existingAlbum
			} else {
				// Otherwise, create the `Album` to move the `Song` to…
				let existingCollection = song.container!.container!
				let newAlbum = Album(atBeginningOf: existingCollection, albumID: freshAlbumID)
				
				// …and then move the `Song` to that `Album`.
				song.index = 0
				song.container = newAlbum
				
				// Make a note of the new `Album`.
				existingAlbums[freshAlbumID] = newAlbum
			}
		}
	}
	
	// MARK: - Create
	
	// Create new managed objects for the new `SongInfo`s, including new `Album`s and `Collection`s to put them in if necessary.
	private func createLibraryItems(newInfos: [SongInfo]) {
		// Group the `SongInfo`s into albums, sorted by the order we’ll add them to our database in.
		let albumsEarliestFirst: [[SongInfo]] = {
			let songsEarliestFirst = newInfos.sorted { $0.dateAddedOnDisk < $1.dateAddedOnDisk }
			let dictionary: [AlbumID: [SongInfo]] = Dictionary(grouping: songsEarliestFirst) { $0.albumID }
			let albums: [[SongInfo]] = dictionary.map { $0.value }
			return albums.sorted { leftGroup, rightGroup in
				leftGroup.first!.dateAddedOnDisk < rightGroup.first!.dateAddedOnDisk
			}
			// We’ll sort `Song`s within each `Album` later, because it depends on whether the existing `Song`s in each `Album` are in album order.
		}()
		
		var existingAlbums: [AlbumID: Album] = {
			let allAlbums = context.fetchPlease(Album.fetchRequest())
			let tuples = allAlbums.map { ($0.albumPersistentID, $0) }
			return Dictionary(uniqueKeysWithValues: tuples)
		}()
		albumsEarliestFirst.forEach { groupOfInfos in
			// Create one group of `Song`s and containers
			if let newAlbum = createSongsAndReturnNewAlbum(
				newInfos: groupOfInfos,
				existingAlbums: existingAlbums
			) {
				existingAlbums[newAlbum.albumPersistentID] = newAlbum
			}
		}
	}
	
	// MARK: Create groups of songs
	
	private func createSongsAndReturnNewAlbum(
		newInfos: [SongInfo],
		existingAlbums: [AlbumID: Album]
	) -> Album? {
		let firstInfo = newInfos.first!
		
		// If we already have a matching `Album` to add the `Song`s to…
		let albumID = firstInfo.albumID
		if let existingAlbum = existingAlbums[albumID] {
			// …then add the `Song`s to that `Album`.
			let songIDs = newInfos.map { $0.songID }
			let isInDefaultOrder: Bool = {
				let infos = existingAlbum.songs(sorted: true).compactMap { $0.songInfo() } // Don’t let `Song`s that we’ll delete later disrupt an otherwise in-order `Album`; just skip over them.
				let orderedInfos = infos.sorted {
					$0.precedesNumerically(inSameAlbum: $1, shouldResortToTitle: true)
				}
				return infos.indices.allSatisfy { index in
					infos[index].songID == orderedInfos[index].songID
				}
			}()
			if isInDefaultOrder {
				songIDs.reversed().forEach {
					let _ = Song(atBeginningOf: existingAlbum, songID: $0)
				}
				
				Self.sortSongsByDefaultOrder(in: existingAlbum)
			} else {
				songIDs.reversed().forEach {
					let _ = Song(atBeginningOf: existingAlbum, songID: $0)
				}
			}
			
			return nil
		} else {
			// Otherwise, create the `Album` to add the `Song`s to…
			let newAlbum: Album = {
				let collection: Collection = {
					if let existing = context.fetchPlease(Collection.fetchRequest()).first { // Order doesn’t matter, because our database should contain exactly 0 or 1 `Collection`s at this point.
						return existing
					}
					let new = Collection(context: context)
					new.index = 0
					new.title = InterfaceText.tilde
					return new
				}()
				return Album(atBeginningOf: collection, albumID: albumID)!
			}()
			
			// …and then add the `Song`s to that `Album`.
			let sortedSongIDs = newInfos.sorted {
				$0.precedesNumerically(inSameAlbum: $1, shouldResortToTitle: true)
			}.map { $0.songID }
			sortedSongIDs.forEach {
				let _ = Song(atEndOf: newAlbum, songID: $0)
			}
			
			return newAlbum
		}
	}
	private static func sortSongsByDefaultOrder(in album: Album) {
		let songs = album.songs(sorted: false)
		
		// `Song`s that don’t have a corresponding `SongInfo` will end up at an undefined position in the result. `Song`s that do will still be in the correct order relative to each other.
		func sortedByDefaultOrder(inSameAlbum: [Song]) -> [Song] {
			var songsAndInfos = songs.map {
				(song: $0,
				 info: $0.songInfo()) // Can be `nil`
			}
			songsAndInfos.sort {
				guard let left = $0.info, let right = $1.info else { return true }
				return left.precedesNumerically(inSameAlbum: right, shouldResortToTitle: true)
			}
			return songsAndInfos.map { $0.song }
		}
		
		let sortedSongs = sortedByDefaultOrder(inSameAlbum: songs)
		Database.renumber(sortedSongs)
	}
	
	// MARK: - Clean Up
	
	private func cleanUpLibraryItems(
		songsToDelete: [Song],
		allInfos: [SongInfo]
	) {
		songsToDelete.forEach { context.delete($0) } // WARNING: Leaves gaps in the `Song` indices within each `Album`, and might leave empty `Album`s. Later, you must delete empty `Album`s and reindex the `Song`s within each `Album`.
		context.unsafe_DeleteEmptyAlbums_WithoutReindexOrCascade()
		context.deleteEmptyCollections()
		
		// Always reindex all `Album`s, because we might have deleted some, which leaves gaps in the indices.
		let allAlbums = context.fetchPlease(Album.fetchRequest_sorted())
		Database.renumber(allAlbums)
		allAlbums.forEach {
			$0.releaseDateEstimate = nil // Deprecated
			let songs = $0.songs(sorted: true)
			Database.renumber(songs)
		}
	}
}
