// 2020-08-10

import CoreData
@preconcurrency import MusicKit
import MediaPlayer
import os

typealias MKSong = MusicKit.Song
typealias MKSection = MusicLibrarySection<MusicKit.Album, MKSong>

@MainActor @Observable final class Librarian {
	@ObservationIgnored private(set) var theCrate: LRCrate? = nil
	private(set) var mkSections: [MusicItemID: MKSection] = [:]
	private(set) var mkSongs: [MusicItemID: MKSong] = [:]
	private(set) var isMerging = false { didSet {
		if isMerging {
			NotificationCenter.default.post(name: Self.willMerge, object: nil)
		} else {
			NotificationCenter.default.post(name: Self.didMerge, object: nil)
		}
	}}
	
	private init() {}
	@ObservationIgnored private let context = Database.viewContext
	private let signposter = OSSignposter(subsystem: "persistence", category: "librarian")
}
extension Librarian {
	static let shared = Librarian()
	func observeMediaPlayerLibrary() {
		let library = MPMediaLibrary.default()
		library.beginGeneratingLibraryChangeNotifications()
		NotificationCenter.default.addObserverOnce(self, selector: #selector(mergeChanges), name: .MPMediaLibraryDidChange, object: library)
		mergeChanges()
	}
	static let willMerge = Notification.Name("LRMusicLibraryWillMerge")
	static let didMerge = Notification.Name("LRMusicLibraryDidMerge")
	func mkSection(albumID: AlbumID) -> MKSection? {
		return mkSections[MusicItemID(String(albumID))]
	}
	func mkSongFetched(mpID: SongID) async -> MKSong? { // Slow; 11ms in 2024.
		var request = MusicLibraryRequest<MKSong>()
		request.filter(matching: \.id, equalTo: MusicItemID(String(mpID)))
		guard
			let response = try? await request.response(),
			response.items.count == 1,
			let mkSong = response.items.first
		else { return nil }
		
		return mkSong
	}
	static func openAppleMusic() {
		guard let musicLibraryURL = URL(string: "music://") else { return }
		UIApplication.shared.open(musicLibraryURL)
	}
}

// MARK: - Private

extension Librarian {
	@objc private func mergeChanges() {
		Task {
#if targetEnvironment(simulator)
			mergeFromAppleMusic(musicKit: [], mediaPlayer: Array(Sim_MusicLibrary.shared.songInfos.values))
#else
			guard let freshMediaItems = MPMediaQuery.songs().items else { return }
			
			let freshSectionsOnly: [MKSection] = await {
				let request = MusicLibrarySectionedRequest<MusicKit.Album, MKSong>()
				guard let response = try? await request.response() else { return [] }
				
				return response.sections
			}()
			let freshSections: [MusicItemID: MKSection] = {
				let tuples = freshSectionsOnly.map { section in (section.id, section) }
				return Dictionary(uniqueKeysWithValues: tuples)
			}()
			let sectionsUnion = mkSections.merging(freshSections) { old, new in new }
			
			// 12,000 songs takes 37ms in 2024.
			let freshSongs: [MusicItemID: MKSong] = {
				let allSongs = freshSections.values.flatMap { $0.items }
				let tuples = allSongs.map { ($0.id, $0) }
				return Dictionary(tuples) { former, latter in latter } // As of iOS 18 developer beta 7, I’ve seen a library where multiple pairs of MusicKit `Song`s had the same `MusicItemID`; they also had the same title, album title, and song artist.
			}()
			let songsUnion = mkSongs.merging(freshSongs) { old, new in new }
			
			// Show new data immediately…
			mkSections = sectionsUnion
			mkSongs = songsUnion
			
			mergeFromAppleMusic(musicKit: freshSectionsOnly, mediaPlayer: freshMediaItems)
			
			try? await Task.sleep(for: .seconds(3)) // …but don’t hide deleted data before removing it from the screen anyway.
			
			mkSections = freshSections
			mkSongs = freshSongs
#endif
		}
	}
	private static let workingOnMusicKitIDs = 10 == 1
	private func mergeFromAppleMusic(musicKit unsortedSections: [MKSection], mediaPlayer unorderedMediaItems: [SongInfo]) {
		isMerging = true
		defer { isMerging = false }
		
		if Self.workingOnMusicKitIDs {
			let allSongs = context.fetchPlease(ZZZSong.fetchRequest())
			allSongs.forEach { context.delete($0) }
			let allAlbums = context.fetchPlease(ZZZAlbum.fetchRequest())
			allAlbums.forEach { context.delete($0) }
			let allCollections = context.fetchPlease(ZZZCollection.fetchRequest())
			allCollections.forEach { context.delete($0) }
			
			mergeFromMusicKit(unsortedSections)
		} else {
			mergeFromMediaPlayer(unorderedMediaItems)
		}
		
		context.savePlease()
	}
	
	// MARK: - MUSICKIT
	
	private func mergeFromMusicKit(_ unsortedSections: [MKSection]) {
		let _merge = signposter.beginInterval("merge")
		defer { signposter.endInterval("merge", _merge) }
		
		let _load = signposter.beginInterval("load")
		theCrate = Disk.loadCrates().first
		signposter.endInterval("load", _load)
		
		let newMKSections: [MKSection] = {
			// Only sort albums themselves; we’ll sort the songs within each album later.
			let now = Date.now
			let sectionsAndDatesCreated: [(section: MKSection, dateCreated: Date)] = unsortedSections.map {(
				section: $0,
				dateCreated: ZZZAlbum.dateCreated($0.items) ?? now
			)}
			let sorted = sectionsAndDatesCreated.sortedStably {
				$0.dateCreated == $1.dateCreated
			} areInOrder: {
				$0.dateCreated > $1.dateCreated
			}
			return sorted.map { $0.section }
		}()
		let newAlbums: [LRAlbum] = newMKSections.map { mkSection in
			LRAlbum(rawID: mkSection.id.rawValue, songs: {
				let mkSongs = mkSection.items.sorted {
					SongOrder.precedesNumerically(strict: true, $0, $1)
				}
				return mkSongs.map { LRSong(rawID: $0.id.rawValue) }
			}())
		}
		let newCrate = LRCrate(title: InterfaceText.tilde, albums: newAlbums)
		theCrate = newCrate
		
		let _save = signposter.beginInterval("save")
		Disk.save([newCrate])
		signposter.endInterval("save", _save)
	}
	
	// MARK: - MEDIA PLAYER
	
	private func mergeFromMediaPlayer(_ unorderedMediaItems: [SongInfo]) {
		// Find out which existing `Song`s we need to delete, and which we need to potentially update.
		// Meanwhile, isolate the `SongInfo`s that we don’t have `Song`s for. We’ll create new `Song`s for them.
		let toUpdate: [(existing: ZZZSong, fresh: SongInfo)]
		let toDelete: [ZZZSong]
		let toCreate: [SongInfo]
		do {
			var updates: [(ZZZSong, SongInfo)] = []
			var deletes: [ZZZSong] = []
			
			var freshInfos: [SongID: SongInfo] = {
				let tuples = unorderedMediaItems.map { info in (info.songID, info) }
				return Dictionary(uniqueKeysWithValues: tuples)
			}()
			let existingSongs: [ZZZSong] = context.fetchPlease(ZZZSong.fetchRequest()) // Not sorted
			existingSongs.forEach { existingSong in
				let songID = existingSong.persistentID
				if let freshInfo = freshInfos[songID] {
					// We have an existing `Song` for this `SongInfo`. We might need to update the `Song`.
					updates.append((existingSong, freshInfo)) // We’ll sort these later.
					
					freshInfos[songID] = nil
				} else {
					// This `Song` no longer corresponds with any `SongInfo` in the library. We’ll delete it.
					deletes.append(existingSong)
				}
			}
			// `freshInfos` now holds the `SongInfo`s that we don’t have `Song`s for.
			
			toUpdate = updates
			toDelete = deletes
			toCreate = freshInfos.map { $0.value } // We’ll sort these later.
		}
		
		updateLibraryItems(existingAndFresh: toUpdate)
		createLibraryItems(newInfos: toCreate)
		cleanUpLibraryItems(songsToDelete: toDelete, allInfos: unorderedMediaItems)
	}
	
	// MARK: - Update
	
	private func updateLibraryItems(existingAndFresh: [(ZZZSong, SongInfo)]) {
		// Merge `Album`s with the same `albumPersistentID`
		let canonicalAlbums: [AlbumID: ZZZAlbum] = mergeClonedAlbumsAndReturnCanonical(existingAndFresh: existingAndFresh)
		
		// Move `Song`s to updated `Album`s
		moveSongsToUpdatedAlbums(
			existingAndFresh: existingAndFresh.map { (song, info) in (song, info.albumID) },
			canonicalAlbums: canonicalAlbums)
	}
	
	private func mergeClonedAlbumsAndReturnCanonical(
		existingAndFresh: [(ZZZSong, SongInfo)]
	) -> [AlbumID: ZZZAlbum] {
		// To merge `Album`s with the same `albumPersistentID`, we’ll move their `Song`s into one `Album`, then delete empty `Album`s.
		// The one `Album` we’ll keep is the uppermost in the user’s custom order.
		let topmostUniqueAlbums: [AlbumID: ZZZAlbum] = {
			let allAlbums = context.fetchPlease(ZZZAlbum.fetchRequest_sorted())
			let tuples = allAlbums.map { ($0.albumPersistentID, $0) }
			return Dictionary(tuples, uniquingKeysWith: { leftAlbum, _ in leftAlbum })
		}()
		
		// Filter to `Song`s in cloned `Album`s
		// Don’t actually move any `Song`s, because we haven’t sorted them yet.
		let unsortedToMove: [ZZZSong] = existingAndFresh.compactMap { (song, _) in
			let album = song.container!
			let canonical = topmostUniqueAlbums[album.albumPersistentID]!
			guard canonical.objectID != album.objectID else { return nil }
			return song
		}
		
		// `Song`s will very rarely make it past this point.
		let toMove = unsortedToMove.sorted { Self.precedesInManualOrder($0, $1) }
		toMove.forEach { song in
			let destination = topmostUniqueAlbums[song.container!.albumPersistentID]!
			song.index = Int64(destination.contents?.count ?? 0)
			song.container = destination
		}
		
		context.unsafe_DeleteEmptyAlbums_WithoutReindexOrCascade()
		
		return topmostUniqueAlbums
	}
	
	private func moveSongsToUpdatedAlbums(
		existingAndFresh: [(ZZZSong, AlbumID)],
		canonicalAlbums: [AlbumID: ZZZAlbum]
	) {
		// If a `Song`’s `Album.albumPersistentID` no longer matches the `Song`’s `SongInfo.albumID`, move that `Song` to an existing or new `Album` with the up-to-date `albumPersistentID`.
		let toUpdate: [(ZZZSong, AlbumID)] = {
			// Filter to `Song`s moved to different `Album`s
			let unsortedOutdated = existingAndFresh.filter { (song, albumID) in
				albumID != song.container!.albumPersistentID
			}
			// Sort by the order the user arranged the `Song`s in the app.
			return unsortedOutdated.sorted { leftTuple, rightTuple in
				Self.precedesInManualOrder(leftTuple.0, rightTuple.0)
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
				let newAlbum = ZZZAlbum(atBeginningOf: existingCollection, albumID: freshAlbumID)
				
				// …and then move the `Song` to that `Album`.
				song.index = 0
				song.container = newAlbum
				
				// Make a note of the new `Album`.
				existingAlbums[freshAlbumID] = newAlbum
			}
		}
	}
	
	private static func precedesInManualOrder(_ left: ZZZSong, _ right: ZZZSong) -> Bool {
		// Checking song index first and collection index last is slightly faster than vice versa.
		guard left.index == right.index else {
			return left.index < right.index
		}
		
		let leftAlbum = left.container!; let rightAlbum = right.container!
		guard leftAlbum.index == rightAlbum.index else {
			return leftAlbum.index < rightAlbum.index
		}
		
		let leftCollection = leftAlbum.container!; let rightCollection = rightAlbum.container!
		return leftCollection.index < rightCollection.index
	}
	
	// MARK: - Create
	
	// Create new managed objects for the new `SongInfo`s, including new `Album`s and `Collection`s to put them in if necessary.
	private func createLibraryItems(newInfos: [SongInfo]) {
		// Group the `SongInfo`s into albums, sorted by the order we’ll add them to our database in.
		let albumsEarliestFirst: [[SongInfo]] = {
			let songsEarliestFirst = newInfos.sorted { $0.dateAddedOnDisk < $1.dateAddedOnDisk }
			let dictionary: [AlbumID: [SongInfo]] = Dictionary(grouping: songsEarliestFirst) { $0.albumID }
			let albumsUnsorted: [[SongInfo]] = dictionary.map { $0.value }
			return albumsUnsorted.sorted { leftGroup, rightGroup in
				leftGroup.first!.dateAddedOnDisk < rightGroup.first!.dateAddedOnDisk
			}
			// We’ll sort `Song`s within each `Album` later, because it depends on whether the existing `Song`s in each `Album` are in album order.
		}()
		
		var existingAlbums: [AlbumID: ZZZAlbum] = {
			let allAlbums = context.fetchPlease(ZZZAlbum.fetchRequest())
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
		existingAlbums: [AlbumID: ZZZAlbum]
	) -> ZZZAlbum? {
		let firstInfo = newInfos.first!
		
		// If we already have a matching `Album` to add the `Song`s to…
		let albumID = firstInfo.albumID
		if let existingAlbum = existingAlbums[albumID] {
			// …then add the `Song`s to that `Album`.
			let isInDefaultOrder: Bool = {
				let existingSongInfos: [some SongInfo] = existingAlbum.songs(sorted: true).compactMap { ZZZSong.info(mpID: $0.persistentID) }
				return existingSongInfos.allNeighborsSatisfy {
					SongOrder.__precedesNumerically(strict: true, $0, $1)
				}
			}()
			let songIDs = newInfos.map { $0.songID }
			if isInDefaultOrder {
				songIDs.reversed().forEach {
					let _ = ZZZSong(atBeginningOf: existingAlbum, songID: $0)
				}
				
				let songsInAlbum = existingAlbum.songs(sorted: true)
				let sorted = SongOrder.sortedNumerically(strict: true, songsInAlbum)
				Database.renumber(sorted)
			} else {
				songIDs.reversed().forEach {
					let _ = ZZZSong(atBeginningOf: existingAlbum, songID: $0)
				}
			}
			
			return nil
		} else {
			// Otherwise, create the `Album` to add the `Song`s to…
			let newAlbum: ZZZAlbum = {
				let collection: ZZZCollection = {
					if let existing = context.fetchPlease(ZZZCollection.fetchRequest()).first { // Order doesn’t matter, because our database should contain exactly 0 or 1 `Collection`s at this point.
						return existing
					}
					let new = ZZZCollection(context: context)
					new.index = 0
					new.title = InterfaceText.tilde
					return new
				}()
				return ZZZAlbum(atBeginningOf: collection, albumID: albumID)!
			}()
			
			// …and then add the `Song`s to that `Album`.
			let sortedInfos = newInfos.sorted {
				return SongOrder.__precedesNumerically(strict: true, $0, $1)
			}
			sortedInfos.indices.forEach { index in
				let newSong = ZZZSong(context: context)
				newSong.container = newAlbum
				newSong.index = Int64(index)
				newSong.persistentID = sortedInfos[index].songID
			}
			
			return newAlbum
		}
	}
	
	// MARK: - Clean Up
	
	private func cleanUpLibraryItems(
		songsToDelete: [ZZZSong],
		allInfos: [SongInfo]
	) {
		songsToDelete.forEach { context.delete($0) } // WARNING: Leaves gaps in the `Song` indices within each `Album`, and might leave empty `Album`s. Later, you must delete empty `Album`s and reindex the `Song`s within each `Album`.
		context.unsafe_DeleteEmptyAlbums_WithoutReindexOrCascade()
		
		// Always reindex all `Album`s, because we might have deleted some, which leaves gaps in the indices.
		let allAlbums = context.fetchPlease(ZZZAlbum.fetchRequest_sorted())
		Database.renumber(allAlbums)
		allAlbums.forEach {
			$0.releaseDateEstimate = nil // Deprecated
			let songs = $0.songs(sorted: true)
			Database.renumber(songs)
		}
	}
}
