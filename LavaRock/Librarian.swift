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
		if !is_merging {
			NotificationCenter.default.post(name: Self.did_merge, object: nil)
		}
	}}
	
	private init() {}
	@ObservationIgnored let context = ZZZDatabase.viewContext
	@ObservationIgnored let signposter = OSSignposter(subsystem: "persistence", category: "librarian")
}
extension Librarian {
	static let shared = Librarian()
	func observe_mpLibrary() {
		let library = MPMediaLibrary.default()
		library.beginGeneratingLibraryChangeNotifications()
		NotificationCenter.default.add_observer_once(self, selector: #selector(media_library_changed), name: .MPMediaLibraryDidChange, object: library)
		media_library_changed()
	}
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
	func mkSong(mpidSong: MPIDSong) async -> MKSong? {
		let mkID = MusicItemID(String(mpidSong))
		if let cached = mkSongs[mkID] { return cached }
		
		await cache_mkSong(mpidSong: mpidSong)
		
		return mkSongs[mkID]
	}
	func cache_mkSong(mpidSong: MPIDSong) async { // Slow; 11ms in 2024.
		let mkID = MusicItemID(String(mpidSong))
		
		var request = MusicLibraryRequest<MKSong>()
		request.filter(matching: \.id, equalTo: mkID)
		guard
			let response = try? await request.response(),
			response.items.count == 1,
			let mkSong = response.items.first
		else { return }
		
		mkSongs[mkID] = mkSong
	}
	static func open_Apple_Music() {
		guard let url = URL(string: "music://") else { return }
		UIApplication.shared.open(url)
	}
	
	@objc private func media_library_changed() {
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
	private func merge_from_Apple_Music(
		musicKit sections_unsorted: [MKSection],
		mediaPlayer mediaItems_unsorted: [InfoSong]
	) async {
		is_merging = true
		defer { is_merging = false }
		
//		merge_from_MusicKit(sections_unsorted)
		merge_from_MediaPlayer(mediaItems_unsorted)
	}
}
