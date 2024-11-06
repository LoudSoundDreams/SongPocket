// 2020-08-10

import CoreData
import MusicKit
import MediaPlayer
import os

typealias MKSong = MusicKit.Song
typealias MKSection = MusicLibrarySection<MusicKit.Album, MKSong>

@MainActor @Observable final class Librarian {
	private(set) var mkSections: [MusicItemID: MKSection] = [:]
	private(set) var mkSongs: [MusicItemID: MKSong] = [:]
	private(set) var is_merging = false { didSet {
		if is_merging {
			NotificationCenter.default.post(name: Self.will_merge, object: nil)
		} else {
			NotificationCenter.default.post(name: Self.did_merge, object: nil)
		}
	}}
	
	private init() {}
	@ObservationIgnored private let context = ZZZDatabase.viewContext
	private let signposter = OSSignposter(subsystem: "persistence", category: "librarian")
}
extension Librarian {
	static let shared = Librarian()
	func observe_mpLibrary() {
		let library = MPMediaLibrary.default()
		library.beginGeneratingLibraryChangeNotifications()
		NotificationCenter.default.add_observer_once(self, selector: #selector(merge_changes), name: .MPMediaLibraryDidChange, object: library)
		merge_changes()
	}
	static let will_merge = Notification.Name("LRMusicLibraryWillMerge")
	static let did_merge = Notification.Name("LRMusicLibraryDidMerge")
	func infoAlbum(mpidAlbum: MPIDAlbum) -> InfoAlbum? {
#if targetEnvironment(simulator)
		guard let sim_album = Sim_MusicLibrary.shared.sim_albums[mpidAlbum]
		else { return nil }
		return InfoAlbum(
			_title: sim_album.title,
			_artist: sim_album.artist,
			_date_released: sim_album.date_released,
			_disc_count: 1
		)
#else
		guard let mkAlbum = mkSection(mpidAlbum: mpidAlbum)
		else { return nil }
		let mkSongs = mkAlbum.items
		return InfoAlbum(
			_title: mkAlbum.title,
			_artist: mkAlbum.artistName,
			_date_released: mkAlbum.releaseDate, // As of iOS 18.2 developer beta 2, this is sometimes wrong. `MusicKit.Album.releaseDate` nonsensically reports the date of its earliest-released song, not its latest; and we can’t even fix it with `reduce` because `MusicKit.Song.releaseDate` always returns `nil`.
			_disc_count: mkSongs.reduce(into: 1) { highest, mkSong in // Bad time complexity
				if let disc = mkSong.discNumber, disc > highest { highest = disc }
			}
		)
#endif
	}
	func mkSection(mpidAlbum: MPIDAlbum) -> MKSection? {
		return mkSections[MusicItemID(String(mpidAlbum))]
	}
	func mkSong_fetched(mpidSong: MPIDSong) async -> MKSong? { // Slow; 11ms in 2024.
		var request = MusicLibraryRequest<MKSong>()
		request.filter(matching: \.id, equalTo: MusicItemID(String(mpidSong)))
		guard
			let response = try? await request.response(),
			response.items.count == 1,
			let mkSong = response.items.first
		else { return nil }
		
		return mkSong
	}
	static func open_Apple_Music() {
		guard let url = URL(string: "music://") else { return }
		UIApplication.shared.open(url)
	}
}

// MARK: - Private

extension Librarian {
	@objc private func merge_changes() {
		Task {
#if targetEnvironment(simulator)
			await merge_from_Apple_Music(musicKit: [], mediaPlayer: Array(Sim_MusicLibrary.shared.sim_songs.values))
#else
			guard let mediaItems_fresh = MPMediaQuery.songs().items else { return }
			
			let array_sections_fresh: [MKSection] = await {
				let request = MusicLibrarySectionedRequest<MusicKit.Album, MKSong>()
				guard let response = try? await request.response() else { return [] }
				
				return response.sections
			}()
			let sections_fresh: [MusicItemID: MKSection] = {
				let tuples = array_sections_fresh.map { section in (section.id, section) }
				return Dictionary(uniqueKeysWithValues: tuples)
			}()
			let sections_union = mkSections.merging(sections_fresh) { old, new in new }
			
			// 12,000 songs takes 37ms in 2024.
			let songs_fresh: [MusicItemID: MKSong] = {
				let songs_all = sections_fresh.values.flatMap { $0.items }
				let tuples = songs_all.map { ($0.id, $0) }
				return Dictionary(tuples) { former, latter in latter } // As of iOS 18 developer beta 7, I’ve seen a library where multiple pairs of MusicKit `Song`s had the same `MusicItemID`; they also had the same title, album title, and song artist.
			}()
			let songs_union = mkSongs.merging(songs_fresh) { old, new in new }
			
			// Show new data immediately…
			mkSections = sections_union
			mkSongs = songs_union
			
			await merge_from_Apple_Music(musicKit: array_sections_fresh, mediaPlayer: mediaItems_fresh)
			
			try? await Task.sleep(for: .seconds(3)) // …but don’t hide deleted data before removing it from the screen anyway.
			
			mkSections = sections_fresh
			mkSongs = songs_fresh
#endif
		}
	}
	private func merge_from_Apple_Music(musicKit sections_unsorted: [MKSection], mediaPlayer mediaItems_unsorted: [InfoSong]) async {
		is_merging = true
		defer { is_merging = false }
		
//		merge_from_MusicKit(sections_unsorted)
		merge_from_MediaPlayer(mediaItems_unsorted)
	}
	
	// MARK: - MUSICKIT
	
	private func merge_from_MusicKit(_ sections_unsorted: [MKSection]) {
		/*
		let _merge = signposter.beginInterval("merge")
		defer { signposter.endInterval("merge", _merge) }
		
		let _load = signposter.beginInterval("load")
//		theCrate = Disk.load_crates().first
		signposter.endInterval("load", _load)
		
		let newMKSections: [MKSection] = {
			// Only sort albums themselves; we’ll sort the songs within each album later.
			let now = Date.now
			let sectionsAndDatesCreated: [(section: MKSection, date_created: Date)] = sections_unsorted.map {(
				section: $0,
				date_created: ZZZAlbum.date_created($0.items) ?? now
			)}
			let sorted = sectionsAndDatesCreated.sortedStably {
				$0.date_created == $1.date_created
			} areInOrder: {
				$0.date_created > $1.date_created
			}
			return sorted.map { $0.section }
		}()
		let newAlbums: [LRAlbum] = newMKSections.map { mkSection in
			LRAlbum(rawID: mkSection.id.rawValue, songs: {
				let mkSongs = mkSection.items.sorted {
					SongOrder.precedes_numerically(strict: true, $0, $1)
				}
				return mkSongs.map { LRSong(rawID: $0.id.rawValue) }
			}())
		}
		let newCrate = LRCrate(title: InterfaceText._tilde, albums: newAlbums)
//		theCrate = newCrate
		
		let _save = signposter.beginInterval("save")
		Disk.save([newCrate])
		signposter.endInterval("save", _save)
		 */
	}
	
	// MARK: - MEDIA PLAYER
	
	private func merge_from_MediaPlayer(_ mediaItems_unsorted: [InfoSong]) {
		// Find out which existing `Song`s we need to delete, and which we need to potentially update.
		// Meanwhile, isolate the `InfoSong`s that we don’t have `Song`s for. We’ll create new `Song`s for them.
		let to_update: [(existing: ZZZSong, fresh: InfoSong)]
		let to_delete: [ZZZSong]
		let to_create: [InfoSong]
		do {
			var updates: [(ZZZSong, InfoSong)] = []
			var deletes: [ZZZSong] = []
			
			var infos_fresh: [MPIDSong: InfoSong] = {
				let tuples = mediaItems_unsorted.map { info in (info.id_song, info) }
				return Dictionary(uniqueKeysWithValues: tuples)
			}()
			let songs_existing: [ZZZSong] = context.fetch_please(ZZZSong.fetchRequest()) // Not sorted
			songs_existing.forEach { song_existing in
				let id_song = song_existing.persistentID
				if let info_fresh = infos_fresh[id_song] {
					// We have an existing `Song` for this `InfoSong`. We might need to update the `Song`.
					updates.append((song_existing, info_fresh)) // We’ll sort these later.
					
					infos_fresh[id_song] = nil
				} else {
					// This `Song` no longer corresponds with any `InfoSong` in the library. We’ll delete it.
					deletes.append(song_existing)
				}
			}
			// `infos_fresh` now holds the `InfoSong`s that we don’t have `Song`s for.
			
			to_update = updates
			to_delete = deletes
			to_create = infos_fresh.map { $0.value } // We’ll sort these later.
		}
		
		update_library_items(existing_and_fresh: to_update)
		create_library_items(infos_new: to_create)
		clean_up_library_items(songs_to_delete: to_delete, infos_all: mediaItems_unsorted)
		
		if WorkingOn.plain_database {
			let lrCrate: LRCrate? = {
				guard let zzzCollection = context.fetch_collection() else { return nil }
				var lrAlbums: [LRAlbum] = []
				zzzCollection.albums(sorted: true).forEach { zzzAlbum in
					var lrSongs: [LRSong] = []
					zzzAlbum.songs(sorted: true).forEach { zzzSong in
						lrSongs.append(
							LRSong(id_song: MPIDSong(zzzSong.persistentID))
						)
					}
					lrAlbums.append(
						LRAlbum(
							id_album: MPIDAlbum(zzzAlbum.albumPersistentID),
							songs: lrSongs)
					)
				}
				return LRCrate(title: zzzCollection.title ?? "", albums: lrAlbums)
			}()
			
//			Disk.save([lrCrate].compacted())
//			ZZZDatabase.destroy()
			
			Library.shared.lrCrate = lrCrate
		} else {
			context.save_please()
		}
	}
	
	// MARK: - Update
	
	private func update_library_items(existing_and_fresh: [(ZZZSong, InfoSong)]) {
		// Merge `Album`s with the same `albumPersistentID`
		let albums_canonical: [MPIDAlbum: ZZZAlbum] = merge_cloned_albums_and_return_canonical(existing_and_fresh: existing_and_fresh)
		
		// Move `Song`s to updated `Album`s
		move_songs_to_updated_albums(
			existing_and_fresh: existing_and_fresh.map { (song, info) in (song, info.id_album) },
			albums_canonical: albums_canonical)
	}
	
	private func merge_cloned_albums_and_return_canonical(
		existing_and_fresh: [(ZZZSong, InfoSong)]
	) -> [MPIDAlbum: ZZZAlbum] {
		// To merge `Album`s with the same `albumPersistentID`, we’ll move their `Song`s into one `Album`, then delete empty `Album`s.
		// The one `Album` we’ll keep is the uppermost in the user’s custom order.
		let topmost_unique: [MPIDAlbum: ZZZAlbum] = {
			let albums_all = context.fetch_please(ZZZAlbum.fetch_request_sorted())
			let tuples = albums_all.map { ($0.albumPersistentID, $0) }
			return Dictionary(tuples, uniquingKeysWith: { left, _ in left })
		}()
		
		// Filter to `Song`s in cloned `Album`s
		// Don’t actually move any `Song`s, because we haven’t sorted them yet.
		let unsorted_to_move: [ZZZSong] = existing_and_fresh.compactMap { (song, _) in
			let album = song.container!
			let canonical = topmost_unique[album.albumPersistentID]!
			guard canonical.objectID != album.objectID else { return nil }
			return song
		}
		
		// `Song`s will very rarely make it past this point.
		let to_move = unsorted_to_move.sorted { Self.precedes_in_manual_order($0, $1) }
		to_move.forEach { song in
			let destination = topmost_unique[song.container!.albumPersistentID]!
			song.index = Int64(destination.contents?.count ?? 0)
			song.container = destination
		}
		
		context.fetch_please(ZZZAlbum.fetchRequest()).forEach { album in
			if album.contents?.count == 0 {
				context.delete(album) // WARNING: Leaves gaps in the `Album` indices within each `Collection`, and doesn’t delete empty `Collection`s. Fix those later.
			}
		}
		
		return topmost_unique
	}
	
	private func move_songs_to_updated_albums(
		existing_and_fresh: [(ZZZSong, MPIDAlbum)],
		albums_canonical: [MPIDAlbum: ZZZAlbum]
	) {
		// If a `Song`’s `Album.albumPersistentID` no longer matches the `Song`’s `InfoSong.albumID`, move that `Song` to an existing or new `Album` with the up-to-date `albumPersistentID`.
		let to_update: [(ZZZSong, MPIDAlbum)] = {
			// Filter to `Song`s moved to different `Album`s
			let unsorted_outdated = existing_and_fresh.filter { (song, id_album) in
				id_album != song.container!.albumPersistentID
			}
			// Sort by the order the user arranged the `Song`s in the app.
			return unsorted_outdated.sorted { leftTuple, rightTuple in
				Self.precedes_in_manual_order(leftTuple.0, rightTuple.0)
			}
		}()
		var albums_existing = albums_canonical
		to_update.reversed().forEach { (song, id_album_fresh) in
			// This `Song`’s `albumPersistentID` has changed. Move it to its up-to-date `Album`.
			// If we already have a matching `Album` to move the `Song` to…
			if let album_existing = albums_existing[id_album_fresh] {
				// …then move the `Song` to that `Album`.
				album_existing.songs(sorted: false).forEach { $0.index += 1 }
				
				song.index = 0
				song.container = album_existing
			} else {
				// Otherwise, create the `Album` to move the `Song` to…
				let collection_existing = song.container!.container!
				let album_new = ZZZAlbum(at_beginning_of: collection_existing, mpidAlbum: id_album_fresh)
				
				// …and then move the `Song` to that `Album`.
				song.index = 0
				song.container = album_new
				
				// Make a note of the new `Album`.
				albums_existing[id_album_fresh] = album_new
			}
		}
	}
	
	private static func precedes_in_manual_order(_ left: ZZZSong, _ right: ZZZSong) -> Bool {
		// Checking song index first and collection index last is slightly faster than vice versa.
		guard left.index == right.index else {
			return left.index < right.index
		}
		
		let album_left = left.container!; let album_right = right.container!
		guard album_left.index == album_right.index else {
			return album_left.index < album_right.index
		}
		
		let collection_left = album_left.container!; let collection_right = album_right.container!
		return collection_left.index < collection_right.index
	}
	
	// MARK: - Create
	
	// Create new managed objects for the new `InfoSong`s, including new `Album`s and `Collection`s to put them in if necessary.
	private func create_library_items(infos_new: [InfoSong]) {
		// Group the `InfoSong`s into albums, sorted by the order we’ll add them to our database in.
		let albums_earliest_first: [[InfoSong]] = {
			let songs_earliest_first = infos_new.sorted { $0.date_added_on_disk < $1.date_added_on_disk }
			let dictionary: [MPIDAlbum: [InfoSong]] = Dictionary(grouping: songs_earliest_first) { $0.id_album }
			let albums_unsorted: [[InfoSong]] = dictionary.map { $0.value }
			return albums_unsorted.sorted { left_group, right_group in
				left_group.first!.date_added_on_disk < right_group.first!.date_added_on_disk
			}
			// We’ll sort `Song`s within each `Album` later, because it depends on whether the existing `Song`s in each `Album` are in album order.
		}()
		
		var albums_existing: [MPIDAlbum: ZZZAlbum] = {
			let albums_all = context.fetch_please(ZZZAlbum.fetchRequest())
			let tuples = albums_all.map { ($0.albumPersistentID, $0) }
			return Dictionary(uniqueKeysWithValues: tuples)
		}()
		albums_earliest_first.forEach { group_of_infos in
			// Create one group of `Song`s and containers
			if let album_new = create_songs_and_return_new_album(
				infos_new: group_of_infos,
				albums_existing: albums_existing
			) {
				albums_existing[album_new.albumPersistentID] = album_new
			}
		}
	}
	
	// MARK: Create groups of songs
	
	private func create_songs_and_return_new_album(
		infos_new: [InfoSong],
		albums_existing: [MPIDAlbum: ZZZAlbum]
	) -> ZZZAlbum? {
		let info_first = infos_new.first!
		
		// If we already have a matching `Album` to add the `Song`s to…
		let id_album = info_first.id_album
		if let album_existing = albums_existing[id_album] {
			// …then add the `Song`s to that `Album`.
			let is_in_default_order: Bool = {
				let infos_existing: [some InfoSong] = album_existing.songs(sorted: true).compactMap { ZZZSong.InfoSong(MPID: $0.persistentID) }
				return infos_existing.all_neighbors_satisfy {
					SongOrder.__precedes_numerically(strict: true, $0, $1)
				}
			}()
			let ids_songs = infos_new.map { $0.id_song }
			if is_in_default_order {
				ids_songs.reversed().forEach {
					let _ = ZZZSong(at_beginning_of: album_existing, mpidSong: $0)
				}
				
				let songs_in_album = album_existing.songs(sorted: true)
				let sorted = SongOrder.sorted_numerically(strict: true, songs_in_album)
				ZZZDatabase.renumber(sorted)
			} else {
				ids_songs.reversed().forEach {
					let _ = ZZZSong(at_beginning_of: album_existing, mpidSong: $0)
				}
			}
			
			return nil
		} else {
			// Otherwise, create the `Album` to add the `Song`s to…
			let album_new: ZZZAlbum = {
				let collection: ZZZCollection = {
					if let existing = context.fetch_collection() {
						return existing
					}
					let new = ZZZCollection(context: context)
					new.index = 0
					new.title = InterfaceText._tilde
					return new
				}()
				return ZZZAlbum(at_beginning_of: collection, mpidAlbum: id_album)!
			}()
			
			// …and then add the `Song`s to that `Album`.
			let infos_sorted = infos_new.sorted {
				return SongOrder.__precedes_numerically(strict: true, $0, $1)
			}
			infos_sorted.indices.forEach { index in
				let song_new = ZZZSong(context: context)
				song_new.container = album_new
				song_new.index = Int64(index)
				song_new.persistentID = infos_sorted[index].id_song
			}
			
			return album_new
		}
	}
	
	// MARK: - Clean Up
	
	private func clean_up_library_items(
		songs_to_delete: [ZZZSong],
		infos_all: [InfoSong]
	) {
		songs_to_delete.forEach { context.delete($0) } // WARNING: Leaves gaps in the `Song` indices within each `Album`, and might leave empty `Album`s.
		
		// Delete empty containers and reindex everything.
		
		guard let collection = context.fetch_collection() else { return }
		
		var albums = collection.albums(sorted: true)
		albums.indices.reversed().forEach { iAlbum in
			let album = albums[iAlbum]
			let songs = album.songs(sorted: true)
			guard !songs.isEmpty else {
				context.delete(album)
				albums.remove(at: iAlbum)
				return
			}
			album.releaseDateEstimate = nil // Deprecated
			ZZZDatabase.renumber(songs)
		}
		guard !albums.isEmpty else {
			context.delete(collection)
			return
		}
		
		ZZZDatabase.renumber(albums)
	}
}
