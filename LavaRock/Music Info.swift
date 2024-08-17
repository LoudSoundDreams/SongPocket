// 2021-12-24

import UIKit
import MusicKit
import MediaPlayer

typealias AlbumID = Int64
typealias SongID = Int64

protocol __SongInfo {
	var _disc: Int? { get }
	var _track: Int? { get }
	var _title: String { get }
	var _artist: String { get }
}
extension MusicKit.Song: __SongInfo {
	var _disc: Int? { discNumber }
	var _track: Int? { trackNumber }
	var _title: String { title }
	var _artist: String { artistName }
}

protocol SongInfo {
	var albumID: AlbumID { get }
	var songID: SongID { get }
	
	var discNumberOnDisk: Int { get }
	var trackNumberOnDisk: Int { get }
	var titleOnDisk: String? { get }
	var artistOnDisk: String? { get }
	var dateAddedOnDisk: Date { get }
}

extension Song {
	static func formatted(disc: Int?, track: Int?, discCount: Int) -> String {
		let trackFormatted: String = {
			guard let track, track != 0 else { return InterfaceText.octothorpe }
			return String(track)
		}()
		let disc = disc ?? 0
		if discCount >= 2 || disc >= 2 {
			return "\(disc)\(InterfaceText.interpunct)\(trackFormatted)"
		} else {
			return trackFormatted
		}
	}
	
	static func info(mpID: SongID) -> (some SongInfo)? {
#if targetEnvironment(simulator)
		return Sim_MusicLibrary.shared.songInfos[mpID]
#else
		return mpMediaItem(id: mpID)
#endif
	}
	private static func mpMediaItem(id: SongID) -> MPMediaItem? {
		let songsQuery = MPMediaQuery.songs()
		songsQuery.addFilterPredicate(MPMediaPropertyPredicate(
			value: id,
			forProperty: MPMediaItemPropertyPersistentID))
		guard let items = songsQuery.items, items.count == 1 else { return nil }
		return items.first
	}
}

// MARK: - Apple Music

import MediaPlayer
extension MPMediaItem: SongInfo {
	final var albumID: AlbumID { AlbumID(bitPattern: albumPersistentID) }
	final var songID: SongID { SongID(bitPattern: persistentID) }
	
	// Media Player reports unknown values as…
	final var discNumberOnDisk: Int { discNumber } // `1`, as of iOS 14.7 developer beta 5
	final var trackNumberOnDisk: Int { albumTrackNumber }
	final var titleOnDisk: String? { title } // …we don’t know, because Apple Music for Mac as of version 1.1.5.74 doesn’t allow blank song titles. But that means we shouldn’t need to move unknown song titles to the end.
	final var artistOnDisk: String? { artist }
	final var dateAddedOnDisk: Date { dateAdded }
}

// MARK: - Simulator

#if targetEnvironment(simulator)
struct Sim_Album {
	let _title: String
	let _artist: String
	let _releaseDate: Date?
	let _dateAdded: Date?
	let artFileName: String
	let _items: [Sim_Song]
}

struct Sim_Song: SongInfo {
	let albumID: AlbumID
	let songID: SongID
	
	let discNumberOnDisk: Int
	let trackNumberOnDisk: Int
	let titleOnDisk: String?
	let artistOnDisk: String?
	let dateAddedOnDisk: Date
}

// Helpers for less typing
struct DemoAlbum {
	let title: String
	let artist: String
	let releaseDate: Date?
	let artFileName: String
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
	static func strategy(iso8601_10Char: String) -> Self {
		return try! Self("\(iso8601_10Char)T23:59:59Z", strategy: .iso8601)
	}
}

@MainActor final class Sim_MusicLibrary {
	static let shared = Sim_MusicLibrary()
	let albumInfos: [AlbumID: Sim_Album]
	let songInfos: [SongID: Sim_Song]
	let currentSongInfo: Sim_Song?
	
	private init() {
		var albumDict: [AlbumID: Sim_Album] = [:]
		var songDict: [SongID: Sim_Song] = [:]
		var albumIDNext: AlbumID = 0
		var songIDNext: SongID = 0
		let demoDate = Date.now
		Self.demoAlbums.forEach { demoAlbum in
			defer { albumIDNext += 1 }
			let sim_songs: [Sim_Song] = demoAlbum.tracks.indices.map { indexInAlbum in
				defer { songIDNext += 1 }
				let demoSong = demoAlbum.tracks[indexInAlbum]
				let result = Sim_Song(
					albumID: albumIDNext,
					songID: songIDNext,
					discNumberOnDisk: 1,
					trackNumberOnDisk: indexInAlbum + 1,
					titleOnDisk: demoSong.title,
					artistOnDisk: demoSong.artist,
					dateAddedOnDisk: demoDate)
				songDict[songIDNext] = result
				return result
			}
			albumDict[albumIDNext] = Sim_Album(
				_title: demoAlbum.title,
				_artist: demoAlbum.artist,
				_releaseDate: demoAlbum.releaseDate,
				_dateAdded: demoDate,
				artFileName: demoAlbum.artFileName,
				_items: sim_songs)
		}
		self.albumInfos = albumDict
		self.songInfos = songDict
		currentSongInfo = songInfos[SongID(0)]
	}
	private static let demoAlbums: [DemoAlbum] = [
		DemoAlbum(
			title: "Hillside",
			artist: "Wanderer",
			releaseDate: .strategy(iso8601_10Char: "2024-05-31"),
			artFileName: "field",
			tracks: [
				.init("Magic"),
				.init("Robot"),
				.init("Last"),
			]),
		DemoAlbum(
			title: "Dawn",
			artist: "Wanderer",
			releaseDate: .strategy(iso8601_10Char: "2024-03-31"),
			artFileName: "city",
			tracks: [
				.init("Amazingly few discotheques provide jukeboxes. The five boxing wizards jump quickly. Pack my box with five dozen liquor jugs. The quick brown fox jumps over the lazy dog.", artist: "Tony Harnell"),
			]),
		DemoAlbum(
			title: "Skyway",
			artist: "Wanderer",
			releaseDate: .strategy(iso8601_10Char: "2024-02-29"),
			artFileName: "sky",
			tracks: [
				.init(""),
			]),
	]
}
#endif
