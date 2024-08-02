// 2021-12-24

import UIKit

typealias AlbumID = Int64
typealias SongID = Int64

protocol SongInfo {
	var albumID: AlbumID { get }
	var songID: SongID { get }
	
	var discCountOnDisk: Int { get }
	var discNumberOnDisk: Int { get }
	var trackNumberOnDisk: Int { get }
	static var unknownTrackNumber: Int { get }
	var titleOnDisk: String? { get }
	var artistOnDisk: String? { get }
	var dateAddedOnDisk: Date { get } // TO DO: Delete
}
extension SongInfo {
	// MARK: - Sorting
	
	// Behavior is undefined if you compare with a `SongInfo` from a different album.
	func precedesNumerically(
		inSameAlbum other: SongInfo,
		shouldResortToTitle: Bool
	) -> Bool {
		// Sort by disc number
		let myDisc = discNumberOnDisk
		let otherDisc = other.discNumberOnDisk
		guard myDisc == otherDisc else {
			return myDisc < otherDisc
		}
		
		let myTrack = trackNumberOnDisk
		let otherTrack = other.trackNumberOnDisk
		
		if shouldResortToTitle {
			guard myTrack != otherTrack else {
				// Sort by song title
				let myTitle = titleOnDisk ?? ""
				let otherTitle = other.titleOnDisk ?? ""
				return myTitle.precedesInFinder(otherTitle)
			}
		} else {
			// At this point, leave elements in the same order if they both have no track number, or the same track number.
			// However, as of iOS 14.7, when using `sorted(by:)`, returning `true` here doesn’t always keep the elements in the same order. Call this method in `sortedMaintainingOrderWhen` to guarantee stable sorting.
			guard myTrack != otherTrack else { return true }
		}
		
		// Move unknown track number to the end
		guard otherTrack != type(of: other).unknownTrackNumber else { return true }
		guard myTrack != Self.unknownTrackNumber else { return false }
		
		return myTrack < otherTrack
	}
	
	// MARK: Formatted attributes
	
	func discAndTrackFormatted() -> String {
		let trackFormatted: String = (trackNumberOnDisk == Self.unknownTrackNumber)
		? InterfaceText.octothorpe
		: String(trackNumberOnDisk)
		if discCountOnDisk >= 2 || discNumberOnDisk >= 2 {
			return "\(discNumberOnDisk)\(InterfaceText.interpunct)\(trackFormatted)"
		}
		return trackFormatted
	}
}

// MARK: - Apple Music

import MediaPlayer
extension MPMediaItem: SongInfo {
	final var albumID: AlbumID { AlbumID(bitPattern: albumPersistentID) }
	final var songID: SongID { SongID(bitPattern: persistentID) }
	
	// Media Player reports unknown values as…
	final var discCountOnDisk: Int { discCount } // `0`, as of iOS 15.0 RC
	final var discNumberOnDisk: Int { discNumber } // `1`, as of iOS 14.7 developer beta 5
	static let unknownTrackNumber = 0 // As of iOS 14.7 developer beta 5
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
	
	let discCountOnDisk: Int
	let discNumberOnDisk: Int
	let trackNumberOnDisk: Int
	static let unknownTrackNumber = 0
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
	let items: [DemoSong]
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
		Self.literals.reversed().forEach { demoAlbum in
			albumIDNext += 1
			let dateAdded = Date.now
			let sim_songs: [Sim_Song] = {
				demoAlbum.items.indices.map { demoSongIndex in
					songIDNext += 1
					let demoSong = demoAlbum.items[demoSongIndex]
					let result = Sim_Song(
						albumID: albumIDNext,
						songID: songIDNext,
						discCountOnDisk: 1,
						discNumberOnDisk: 1,
						trackNumberOnDisk: demoSongIndex,
						titleOnDisk: demoSong.title,
						artistOnDisk: demoSong.artist,
						dateAddedOnDisk: dateAdded)
					songDict[songIDNext] = result
					return result
				}
			}()
			albumDict[albumIDNext] = Sim_Album(
				_title: demoAlbum.title,
				_artist: demoAlbum.artist,
				_releaseDate: demoAlbum.releaseDate,
				_dateAdded: dateAdded,
				artFileName: demoAlbum.artFileName,
				_items: sim_songs)
		}
		self.albumInfos = albumDict
		self.songInfos = songDict
		currentSongInfo = songInfos[SongID(0)]
	}
	private static let literals: [DemoAlbum] = [
		DemoAlbum(
			title: "Fez",
			artist: "Disasterpeace",
			releaseDate: .strategy(iso8601_10Char: "2012-04-20"),
			artFileName: "Fez",
			items: [
				.init("Adventure"),
				.init("Puzzle"),
				.init("Beyond"),
				.init("Progress"),
				.init("Beacon"),
				.init("Flow"),
				.init("Formations"),
				.init("Legend"),
				.init("Compass"),
				.init("Forgotten"),
				.init("Sync"),
				.init("Glitch"),
				.init("Fear"),
				.init("Spirit"),
				.init("Nature"),
				.init("Knowledge"),
				.init("Death"),
				.init("Memory"),
				.init("Pressure"),
				.init("Nocturne"),
				.init("Age"),
				.init("Majesty"),
				.init("Continuum"),
				.init("Home"),
				.init("Reflection"),
				.init("Love"),
			]),
		DemoAlbum(
			title: "Sonic Adventure",
			artist: "Various Artists",
			releaseDate: .strategy(iso8601_10Char: "1999-01-20"),
			artFileName: "Sonic Adventure",
			items: [
				.init("Amazingly few discotheques provide jukeboxes. The five boxing wizards jump quickly. Pack my box with five dozen liquor jugs. The quick brown fox jumps over the lazy dog.", artist: "Tony Harnell"),
			]),
		DemoAlbum(
			title: "Star Trek II",
			artist: "James Horner",
			releaseDate: .strategy(iso8601_10Char: "1982-06-04"),
			artFileName: "Star Trek II",
			items: [
				.init(""),
			]),
		DemoAlbum(
			title: "Star Trek IV",
			artist: "Leonard Rosenman",
			releaseDate: .strategy(iso8601_10Char: "1986-11-26"),
			artFileName: "Star Trek IV",
			items: [
				.init(""),
			]),
	]
}
#endif
