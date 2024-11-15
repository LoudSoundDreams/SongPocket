// 2021-12-24

import MusicKit

struct InfoAlbum {
	let _title: String
	let _artist: String
	let _date_released: Date?
	let _disc_count: Int
}
#if targetEnvironment(simulator)
struct Sim_Album {
	let title: String
	let artist: String
	let date_released: Date?
	
	let _date_added: Date?
	let art_file_name: String
	let _items: [Sim_Song]
}
#endif

struct InfoSong__ {
	let _title: String
	let _artist: String
	let _disc: Int?
	let _track: Int?
}

import MediaPlayer

typealias MPIDAlbum = Int64
typealias MPIDSong = Int64

protocol InfoSong {
	var id_album: MPIDAlbum { get }
	var id_song: MPIDSong { get }
	
	var disc_number_on_disk: Int { get }
	var track_number_on_disk: Int { get }
	var title_on_disk: String? { get }
	var date_added_on_disk: Date { get }
}

extension ZZZAlbum {
	static func date_created(_ mkSongs: any Sequence<MKSong>) -> Date? {
		return mkSongs.reduce(into: nil) { result, mkSong in
			guard let date_added = mkSong.libraryAddedDate else { return }
			guard let earliest_so_far = result else { result = date_added; return }
			if date_added < earliest_so_far { result = date_added }
		}
	}
}

extension ZZZSong {
	@MainActor static func InfoSong(MPID: MPIDSong) -> (some InfoSong)? {
#if targetEnvironment(simulator)
		return Sim_MusicLibrary.shared.sim_songs[MPID]
#else
		return mpMediaItem(id: MPID)
#endif
	}
	private static func mpMediaItem(id: MPIDSong) -> MPMediaItem? {
		let query_songs = MPMediaQuery.songs()
		query_songs.addFilterPredicate(MPMediaPropertyPredicate(
			value: id,
			forProperty: MPMediaItemPropertyPersistentID))
		guard let items = query_songs.items, items.count == 1 else { return nil }
		return items.first
	}
}

// MARK: - Apple Music

extension MPMediaItem: InfoSong {
	final var id_album: MPIDAlbum { MPIDAlbum(albumPersistentID) }
	final var id_song: MPIDSong { MPIDSong(persistentID) }
	
	// Media Player reports unknown values as…
	final var disc_number_on_disk: Int { discNumber } // `1`, as of iOS 14.7 developer beta 5
	final var track_number_on_disk: Int { albumTrackNumber }
	final var title_on_disk: String? { title } // …we don’t know, because Apple Music for Mac as of version 1.1.5.74 doesn’t allow blank song titles. But that means we shouldn’t need to move unknown song titles to the end.
	final var date_added_on_disk: Date { dateAdded }
}

// MARK: - Simulator

#if targetEnvironment(simulator)
struct Sim_Song: InfoSong {
	let id_album: MPIDAlbum
	let id_song: MPIDSong
	
	let disc_number_on_disk: Int
	let track_number_on_disk: Int
	let title_on_disk: String?
	let date_added_on_disk: Date
}

// Helpers for less typing
struct DemoAlbum {
	let title: String
	let artist: String
	let release_date: Date?
	let art_file_name: String
	let tracks: [DemoSong]
}
struct DemoSong {
	let title: String
	let artist: String
	init(_ title: String, artist: String? = nil) {
		self.title = title
		self.artist = artist ?? ""
	}
}
private extension Date {
	// "1984-01-24"
	static func strategy(iso8601_10char: String) -> Self {
		return try! Self("\(iso8601_10char)T23:59:59Z", strategy: .iso8601)
	}
}

@MainActor final class Sim_MusicLibrary {
	static let shared = Sim_MusicLibrary()
	let sim_albums: [MPIDAlbum: Sim_Album]
	let sim_songs: [MPIDSong: Sim_Song]
	let sim_song_current: Sim_Song?
	
	private init() {
		var d_albums: [MPIDAlbum: Sim_Album] = [:]
		var d_songs: [MPIDSong: Sim_Song] = [:]
		var id_album_next: MPIDAlbum = 0
		var id_song_next: MPIDSong = 0
		let date_demo = Date.now
		Self.demo_albums.forEach { demo_album in
			defer { id_album_next += 1 }
			let items: [Sim_Song] = demo_album.tracks.indices.map { i_in_album in
				defer { id_song_next += 1 }
				let demo_song = demo_album.tracks[i_in_album]
				let result = Sim_Song(
					id_album: id_album_next,
					id_song: id_song_next,
					disc_number_on_disk: 1,
					track_number_on_disk: i_in_album + 1,
					title_on_disk: demo_song.title,
					date_added_on_disk: date_demo)
				d_songs[id_song_next] = result
				return result
			}
			d_albums[id_album_next] = Sim_Album(
				title: demo_album.title,
				artist: demo_album.artist,
				date_released: demo_album.release_date,
				_date_added: date_demo,
				art_file_name: demo_album.art_file_name,
				_items: items)
		}
		
//		self.sim_albums = [:]
//		self.sim_songs = [:]
		
		self.sim_albums = d_albums
		self.sim_songs = d_songs
		sim_song_current = sim_songs[MPIDSong(0)]
	}
	private static let demo_albums: [DemoAlbum] = [
		DemoAlbum(
			title: "Dawn",
			artist: "Wanderer",
			release_date: .strategy(iso8601_10char: "2024-05-31"),
			art_file_name: "city",
			
			tracks: [
				.init("Magic"),
				.init("Robot"),
				.init("Last"),
			]),
		DemoAlbum(
			title: "Hillside",
			artist: "Wanderer",
			release_date: .strategy(iso8601_10char: "2024-03-31"),
			art_file_name: "field",
			tracks: [
				.init("Amazingly few discotheques provide jukeboxes. The five boxing wizards jump quickly. Pack my box with five dozen liquor jugs. The quick brown fox jumps over the lazy dog.", artist: "Tony Harnell"),
			]),
		DemoAlbum(
			title: "Skyway",
			artist: "Wanderer",
			release_date: .strategy(iso8601_10char: "2024-02-29"),
			art_file_name: "sky",
			tracks: [
				.init(""),
			]),
	]
}
#endif
