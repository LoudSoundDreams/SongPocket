// 2020-08-10

import MusicKit
import MediaPlayer
import os

typealias MKSection = MusicLibrarySection<MusicKit.Album, MKSong>
typealias MKSong = MusicKit.Song

typealias UAlbum = MPMediaEntityPersistentID
typealias USong = MPMediaEntityPersistentID

struct AlbumInfo {
	let _title: String
	let _artist: String
	let _date_first_added: Date?
	let _date_released: Date?
	let _disc_max: Int
}
struct SongInfo {
	let _disc: Int?
	let _track: Int?
	let _title: String
	let _artist: String
}

@MainActor @Observable final class AppleCatalog {
	private init() {}
	
	private(set) var mkSections_cache: [MusicItemID: MKSection] = [:]
	
	@ObservationIgnored private(set) var mkSong_for_uSong_cache: [USong: MKSong] = [:] { didSet {
		signal_mkSong_cache += 1
	}}
	fileprivate(set) var signal_mkSong_cache = 0
}
extension AppleCatalog {
	@ObservationIgnored static let shared = AppleCatalog()
	@ObservationIgnored private static let signposter = OSSignposter(subsystem: "apple catalog", category: .pointsOfInterest)
	
	func watch() {
		let library = MPMediaLibrary.default()
		library.beginGeneratingLibraryChangeNotifications()
		NotificationCenter.default.addObserver_once(self, selector: #selector(merge), name: .MPMediaLibraryDidChange, object: library)
		merge()
	}
	
	func albumInfo(_ uAlbum: UAlbum) -> AlbumInfo? {
		guard let mkSection = mkSections_cache[MusicItemID(String(uAlbum))]
		else { return nil }
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
	
	func fetch_mkSong(for_uSong uSong: USong) async -> MKSong? {
		if let cached = mkSong_for_uSong_cache[uSong] { return cached }
		
		await cache_mkSong(for_uSong: uSong)
		
		return mkSong_for_uSong_cache[uSong]
	}
	func cache_mkSong(for_uSong uSong: USong) async { // Slow; 11ms in 2024.
		let _cache = Self.signposter.beginInterval("cache")
		defer { Self.signposter.endInterval("cache", _cache) }
		
		var request = MusicLibraryRequest<MKSong>()
		request.filter(matching: \.id, equalTo: MusicItemID(String(uSong)))
		guard
			let response = try? await request.response(),
			response.items.count == 1,
			let mkSong = response.items.first
		else { return }
		
		mkSong_for_uSong_cache[uSong] = mkSong
	}
	
	@objc private func merge() {
		Task {
			let mkRequest = MusicLibrarySectionedRequest<MusicKit.Album, MKSong>()
			let mpQuery = MPMediaQuery.songs() // As of iOS 18.2, accessing `MPMediaItemCollection.items` is slow, so avoid it.
			mpQuery.groupingType = .album // Sorts `items` by album title, then within each album cluster by track order. (Also makes `collections` an array of albums, but that’s not why we’re interested.)
			guard
				let mk_array: [MKSection] =  try? await mkRequest.response().sections,
				let mpSongs = mpQuery.items
			else {
#if targetEnvironment(simulator)
				await Librarian.merge_DummyCatalog()
#endif
				return
			}
			
			let mk_dict: [MusicItemID: MKSection] = {
				let tuples = mk_array.map { section in (section.id, section) }
				return Dictionary(uniqueKeysWithValues: tuples)
			}()
			let mk_union = mkSections_cache.merging(mk_dict) { old, new in new }
			mkSections_cache = mk_union // Show new data immediately …
			
			await Librarian.merge_MediaPlayer(mpSongs)
			
			try? await Task.sleep(for: .seconds(3)) // … but don’t hide deleted data before removing it from the screen anyway.
			
			mkSections_cache = mk_dict
		}
	}
}

#if targetEnvironment(simulator)
@MainActor enum DummyCatalog {
	static func dummy_albumInfo(_ uAlbum: UInt64) -> AlbumInfo? {
		let dAlbum = dummyAlbums[Int(uAlbum)]
		return AlbumInfo(
			_title: dAlbum.title,
			_artist: dAlbum.artist,
			_date_first_added: nil,
			_date_released: dAlbum.date,
			_disc_max: 0)
	}
	static let dummyAlbums: [DummyAlbum] = [
		.init(
			title: "Berry",
			artist: "Chano",
			date: .ten_char("2015-01-10"),
			image: "Chano",
			indices_dummySongs: [
				0
			]),
		.init(
			title: "Beautiful Dreamer",
			artist: "fhána",
			date: .ten_char("2023-12-20"),
			image: "fhana",
			indices_dummySongs: [
				1, 2
			]),
		.init(
			title: "The Good Witch",
			artist: "Maisie Peters",
			date: .ten_char("2023-06-23"),
			image: "Maisie",
			indices_dummySongs: [
				3
			]),
	]
	
	static let i_dummySong_current: UInt64 = 1
	static let dummySongs: [DummySong] = [
		.init("The Magical Robot and the Boy"),
		.init("Hikarimau Fuyunohi Ni"),
		.init("Last Pages"),
		.init("The Last One"),
	]
}

struct DummyAlbum {
	let title: String
	let artist: String
	let date: Date?
	let image: String
	let indices_dummySongs: [Int]
}
struct DummySong {
	let title: String
	let artist: String
	init(_ title: String, artist: String = "") {
		self.title = title
		self.artist = artist
	}
}

private extension Date {
	static func ten_char(_ input: String) -> Self { // "1984-01-24"
		return try! Self("\(input)T23:59:59Z", strategy: .iso8601)
	}
}
#endif
