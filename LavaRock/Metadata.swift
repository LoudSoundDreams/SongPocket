// 2021-12-24

struct AlbumInfo {
	let _title: String
	let _artist: String
	let _date_first_added: Date?
	let _date_released: Date?
	let _num_discs: Int
}
struct SongInfo {
	let _disc: Int?
	let _track: Int?
	let _title: String
	let _artist: String
}

#if targetEnvironment(simulator)
@MainActor final class Sim_MusicLibrary {
	private static let demoAlbums: [DemoAlbum] = [
		DemoAlbum(
			title: "Hillside",
			artist: "Wanderer",
			date_released: .strategy(iso8601_10char: "2024-05-31"),
			image_file: "field",
			tracks: [
				.init("Magic"),
				.init("Robot"),
				.init("Last"),
			]),
		DemoAlbum(
			title: "Dawn",
			artist: "Wanderer",
			date_released: .strategy(iso8601_10char: "2024-03-31"),
			image_file: "city",
			tracks: [
				.init("Amazingly few discotheques provide jukeboxes. The five boxing wizards jump quickly. Pack my box with five dozen liquor jugs. The quick brown fox jumps over the lazy dog.", artist: "Tony Harnell"),
			]),
		DemoAlbum(
			title: "Skyway",
			artist: "Wanderer",
			date_released: .strategy(iso8601_10char: "2024-02-29"),
			image_file: "sky",
			tracks: [
				.init(""),
			]),
	]
}

struct DemoAlbum {
	let title: String
	let artist: String
	let date_released: Date?
	let image_file: String
	let tracks: [DemoSong]
}
private extension Date {
	static func strategy(iso8601_10char: String) -> Self { // "1984-01-24"
		return try! Self("\(iso8601_10char)T23:59:59Z", strategy: .iso8601)
	}
}

struct DemoSong {
	let title: String
	let artist: String
	init(_ title: String, artist: String = "") {
		self.title = title
		self.artist = artist
	}
}
#endif

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
extension ZZZSong {
	@MainActor static func infoSong(MPID: MPIDSong) -> (some InfoSong)? {
		return mpMediaItem(id: MPID)
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
extension MPMediaItem: InfoSong {
	final var id_album: MPIDAlbum { MPIDAlbum(bitPattern: albumPersistentID) }
	final var id_song: MPIDSong { MPIDSong(bitPattern: persistentID) }
	// Media Player reports unknown values as …
	final var disc_number_on_disk: Int { discNumber } // `1`, as of iOS 14.7 developer beta 5
	final var track_number_on_disk: Int { albumTrackNumber }
	final var title_on_disk: String? { title } // … we don’t know, because Apple Music for Mac as of version 1.1.5.74 doesn’t allow blank song titles. But that means we shouldn’t need to move unknown song titles to the end.
	final var date_added_on_disk: Date { dateAdded }
}
