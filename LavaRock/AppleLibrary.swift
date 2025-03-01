// 2020-08-10

import MusicKit
import MediaPlayer
import os

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
}
extension AppleLibrary {
	@ObservationIgnored static let shared = AppleLibrary()
	@ObservationIgnored private static let signposter = OSSignposter(subsystem: "apple library", category: .pointsOfInterest)
	
	static func open_Apple_Music() {
		guard let url = URL(string: "music://") else { return }
		UIApplication.shared.open(url)
	}
	
	func watch() {
		let library = MPMediaLibrary.default()
		library.beginGeneratingLibraryChangeNotifications()
		NotificationCenter.default.add_observer_once(self, selector: #selector(merge_changes), name: .MPMediaLibraryDidChange, object: library)
		merge_changes()
	}
	@ObservationIgnored static let did_merge = Notification.Name("LR_MusicLibraryDidMerge")
	
	func albumInfo(uAlbum: UAlbum) -> AlbumInfo? {
		guard let mkSection = mkSections_cache[MusicItemID(String(uAlbum))] else { return nil }
		let mkSongs = mkSection.items // Slow.
		return AlbumInfo(
			_title: mkSection.title,
			_artist: mkSection.artistName,
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
			_date_released: mkSection.releaseDate, // As of iOS 18.2 developer beta 2, this is sometimes wrong. `MusicKit.Album.releaseDate` nonsensically reports the date of its earliest-released song, not its latest; and we can’t even fix it with `reduce` because `MusicKit.Song.releaseDate` always returns `nil`.
			_disc_max: {
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
		let _cache = Self.signposter.beginInterval("cache")
		defer { Self.signposter.endInterval("cache", _cache) }
		
		var request = MusicLibraryRequest<MKSong>()
		request.filter(matching: \.id, equalTo: MusicItemID(String(uSong)))
		guard
			let response = try? await request.response(),
			response.items.count == 1,
			let mkSong = response.items.first
		else { return }
		
		mkSongs_cache[uSong] = mkSong
	}
	
	@objc private func merge_changes() {
		Task {
			let mkRequest = MusicLibrarySectionedRequest<MusicKit.Album, MKSong>()
			let mpQuery = MPMediaQuery.songs() // As of iOS 18.2, accessing `MPMediaItemCollection.items` is slow, so avoid it.
			mpQuery.groupingType = .album // Sorts `items` by album title, then within each album cluster by track order. (Also makes `collections` an array of albums, but that’s not why we’re interested.)
			guard
				let mk_array: [MKSection] =  try? await mkRequest.response().sections,
				let mpSongs = mpQuery.items
			else { return }
			
			let mk_dict: [MusicItemID: MKSection] = {
				let tuples = mk_array.map { section in (section.id, section) }
				return Dictionary(uniqueKeysWithValues: tuples)
			}()
			let mk_union = mkSections_cache.merging(mk_dict) { old, new in new }
			mkSections_cache = mk_union // Show new data immediately …
			
			is_merging = true
			await Librarian.merge_MediaPlayer_items(mpSongs)
			
			Librarian.save()
			is_merging = false
			
			try? await Task.sleep(for: .seconds(3)) // … but don’t hide deleted data before removing it from the screen anyway.
			
			mkSections_cache = mk_dict
		}
	}
}
