// 2021-12-24

import Foundation

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
struct DemoSong {
	let title: String
	let artist: String
	init(_ title: String, artist: String = "") {
		self.title = title
		self.artist = artist
	}
}

private extension Date {
	static func strategy(iso8601_10char: String) -> Self { // "1984-01-24"
		return try! Self("\(iso8601_10char)T23:59:59Z", strategy: .iso8601)
	}
}
#endif
