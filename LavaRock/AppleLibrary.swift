// 2020-08-10

import MusicKit
import MediaPlayer

typealias MKSection = MusicLibrarySection<MusicKit.Album, MKSong>
typealias MKSong = MusicKit.Song

typealias UAlbum = MPMediaEntityPersistentID
typealias USong = MPMediaEntityPersistentID

@MainActor @Observable final class AppleLibrary {
	private(set) var mkSections_cache: [MusicItemID: MKSection] = [:]
	private(set) var mkSongs_cache: [USong: MKSong] = [:]
	private(set) var is_merging = false { didSet {
		if !is_merging {
			NotificationCenter.default.post(name: Self.did_merge, object: nil)
		}
	}}
	
	private init() {}
	@ObservationIgnored let context = ZZZDatabase.__viewContext
}
extension AppleLibrary {
	static let shared = AppleLibrary()
	func watch() {
		let library = MPMediaLibrary.default()
		library.beginGeneratingLibraryChangeNotifications()
		NotificationCenter.default.add_observer_once(self, selector: #selector(merge_changes), name: .MPMediaLibraryDidChange, object: library)
		merge_changes()
	}
	static let did_merge = Notification.Name("LRMusicLibraryDidMerge")
	func albumInfo(uAlbum: UAlbum) -> AlbumInfo? {
		guard let mkAlbum = mkSections_cache[MusicItemID(String(uAlbum))] else { return nil }
		let mkSongs = mkAlbum.items
		return AlbumInfo(
			_title: mkAlbum.title,
			_artist: mkAlbum.artistName,
			_date_first_added: {
				/*
				 As of iOS 17.6 developer beta 2, `MusicKit.Album.libraryAddedDate` reports the latest date you added one of its songs, not the earliest. That matches how the Apple Music app sorts its Library tab’s Recently Added section, but doesn’t match how it sorts playlists by “Recently Added”, which is actually by date created.
				 I prefer using date created, because it’s stable: that’s the order we naturally get by adding new albums at the top when we first import them, regardless of when that is.
				 */
				return mkSongs.reduce(into: nil) { // Bad time complexity
					result, mkSong in
					guard let date_added = mkSong.libraryAddedDate else { return }
					// MusicKit’s granularity is 1 second; we can’t meaningfully compare items added within the same second.
					guard let earliest_so_far = result else {
						result = date_added
						return
					}
					if date_added < earliest_so_far {
						result = date_added
					}
				}
			}(),
			_date_released: mkAlbum.releaseDate, // As of iOS 18.2 developer beta 2, this is sometimes wrong. `MusicKit.Album.releaseDate` nonsensically reports the date of its earliest-released song, not its latest; and we can’t even fix it with `reduce` because `MusicKit.Song.releaseDate` always returns `nil`.
			_num_discs: {
				return mkSongs.reduce(into: 1) { // Bad time complexity
					highest_so_far, mkSong in
					if let disc = mkSong.discNumber, disc > highest_so_far {
						highest_so_far = disc
					}
				}
			}()
		)
	}
	func mkSong_fetched(uSong: USong) async -> MKSong? {
		if let cached = mkSongs_cache[uSong] { return cached }
		
		await cache_mkSong(uSong: uSong)
		
		return mkSongs_cache[uSong]
	}
	func cache_mkSong(uSong: USong) async { // Slow; 11ms in 2024.
		var request = MusicLibraryRequest<MKSong>()
		request.filter(matching: \.id, equalTo: MusicItemID(String(uSong)))
		guard
			let response = try? await request.response(),
			response.items.count == 1,
			let mkSong = response.items.first
		else { return }
		
		mkSongs_cache[uSong] = mkSong
	}
	static func open_Apple_Music() {
		guard let url = URL(string: "music://") else { return }
		UIApplication.shared.open(url)
	}
	
	@objc private func merge_changes() {
		Task {
			guard
				let mpAlbums = MPMediaQuery.albums().collections,
				let __mpSongs = MPMediaQuery.songs().items
			else { return }
			
			let array_mkSections: [MKSection]? = await {
				let request = MusicLibrarySectionedRequest<MusicKit.Album, MKSong>()
				return try? await request.response().sections
			}()
			guard let array_mkSections else { return }
			
			let fresh_mkSections: [MusicItemID: MKSection] = {
				let tuples = array_mkSections.map { section in (section.id, section) }
				return Dictionary(uniqueKeysWithValues: tuples)
			}()
			
			// Show new data immediately…
			let union_mkSections = mkSections_cache.merging(fresh_mkSections) { old, new in new }
			mkSections_cache = union_mkSections
			
			is_merging = true
			__merge_MediaPlayer_items(__mpSongs)
			await Librarian.merge_MediaPlayer_items(mpAlbums)
			
			Librarian.save()
			is_merging = false
			
			// …but don’t hide deleted data before removing it from the screen anyway.
			try? await Task.sleep(for: .seconds(3))
			
			mkSections_cache = fresh_mkSections
		}
	}
}
