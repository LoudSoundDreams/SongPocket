// 2020-08-10

import MusicKit
import MediaPlayer

typealias MKSong = MusicKit.Song
typealias MKSection = MusicLibrarySection<MusicKit.Album, MKSong>

@MainActor @Observable final class AppleLibrary {
	private(set) var mkSections: [MusicItemID: MKSection] = [:]
	private(set) var mkSongs_cache: [MPIDSong: MKSong] = [:]
	private(set) var is_merging = false { didSet {
		if !is_merging {
			NotificationCenter.default.post(name: Self.did_merge, object: nil)
		}
	}}
	
	private init() {}
	@ObservationIgnored let context = ZZZDatabase.viewContext
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
	func infoAlbum(mpid: MPIDAlbum) -> InfoAlbum? {
#if targetEnvironment(simulator)
		guard let sim_album = Sim_MusicLibrary.shared.sim_albums[mpid] else { return nil }
		return InfoAlbum(
			_title: sim_album.title,
			_artist: sim_album.artist,
			_date_released: sim_album.date_released,
			_disc_count: 1)
#else
		guard let mkAlbum = mkSection_cached(mpid: mpid) else { return nil }
		return InfoAlbum(
			_title: mkAlbum.title,
			_artist: mkAlbum.artistName,
			_date_released: mkAlbum.releaseDate, // As of iOS 18.2 developer beta 2, this is sometimes wrong. `MusicKit.Album.releaseDate` nonsensically reports the date of its earliest-released song, not its latest; and we can’t even fix it with `reduce` because `MusicKit.Song.releaseDate` always returns `nil`.
			_disc_count: mkAlbum.items.reduce(into: 1) { // Bad time complexity
				highest, mkSong in
				if let disc = mkSong.discNumber, disc > highest { highest = disc }
			}
		)
#endif
	}
	func mkSection_cached(mpid: MPIDAlbum) -> MKSection? {
		return mkSections[MusicItemID(String(mpid))]
	}
	func mkSong_cached_or_fetched(mpid: MPIDSong) async -> MKSong? {
		if let cached = mkSongs_cache[mpid] { return cached }
		
		await cache_mkSong(mpid: mpid)
		
		return mkSongs_cache[mpid]
	}
	func cache_mkSong(mpid: MPIDSong) async { // Slow; 11ms in 2024.
		var request = MusicLibraryRequest<MKSong>()
		request.filter(matching: \.id, equalTo: MusicItemID(String(mpid)))
		guard
			let response = try? await request.response(),
			response.items.count == 1,
			let mkSong = response.items.first
		else { return }
		
		mkSongs_cache[mpid] = mkSong
	}
	static func open_Apple_Music() {
		guard let url = URL(string: "music://") else { return }
		UIApplication.shared.open(url)
	}
	
	@objc private func merge_changes() {
		Task {
#if targetEnvironment(simulator)
			__merge_MediaPlayer_items(Array(Sim_MusicLibrary.shared.sim_songs.values))
#else
			guard
				let fresh_mpAlbums = MPMediaQuery.albums().collections,
				let __fresh_mpSongs = MPMediaQuery.songs().items
			else { return }
			
			let fresh_mkSections: [MKSection] = await {
				let request = MusicLibrarySectionedRequest<MusicKit.Album, MKSong>()
				guard let response = try? await request.response() else { return [] }
				
				return response.sections
			}()
			let fresh_mkSections_dict: [MusicItemID: MKSection] = {
				let tuples = fresh_mkSections.map { section in (section.id, section) }
				return Dictionary(uniqueKeysWithValues: tuples)
			}()
			let union_mkSections_dict = mkSections.merging(fresh_mkSections_dict) { old, new in new }
			
			// Show new data immediately…
			mkSections = union_mkSections_dict
			
			is_merging = true
			__merge_MediaPlayer_items(__fresh_mpSongs)
			Librarian.merge_MediaPlayer_items(fresh_mpAlbums)
			Librarian.save()
			is_merging = false
			
			try? await Task.sleep(for: .seconds(3)) // …but don’t hide deleted data before removing it from the screen anyway.
			
			mkSections = fresh_mkSections_dict
#endif
		}
	}
}
