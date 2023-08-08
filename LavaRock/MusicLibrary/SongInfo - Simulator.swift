//
//  SongInfo - Simulator.swift
//  LavaRock
//
//  Created by h on 2023-08-08.
//

#if targetEnvironment(simulator)
import MediaPlayer
import UIKit
import OSLog

enum Sim_Global {
	static let currentSongID = SongID(420)
	static var currentSong: Song? = nil
}

struct Sim_SongInfo: SongInfo {
	let albumID: AlbumID
	let songID: SongID
	
	let albumArtistOnDisk: String?
	let albumTitleOnDisk: String?
	let discCountOnDisk: Int
	let discNumberOnDisk: Int
	let trackNumberOnDisk: Int
	static let unknownTrackNumber = MPMediaItem.unknownTrackNumber
	let titleOnDisk: String?
	let artistOnDisk: String?
	let dateAddedOnDisk: Date
	let releaseDateOnDisk: Date?
	func coverArt(atLeastInPoints: CGSize) -> UIImage? {
		let signposter = OSSignposter()
		let state = signposter.beginInterval("Sim: draw cover art")
		defer {
			signposter.endInterval("Sim: draw cover art", state)
		}
		guard let fileName = coverArtFileName else {
			return nil
		}
		return UIImage(named: fileName)
	}
	private let coverArtFileName: String?
}
extension Sim_SongInfo {
	static var all: [Self] {
//		return []
		
		let tall = AlbumIDDispenser.takeNumber()
		let wide = AlbumIDDispenser.takeNumber()
		let noArtwork = AlbumIDDispenser.takeNumber()
		let khan = AlbumIDDispenser.takeNumber()
		let voyage = AlbumIDDispenser.takeNumber()
		let fez = AlbumIDDispenser.takeNumber()
		let sonic = AlbumIDDispenser.takeNumber()
		return [
			Sim_SongInfo(
				albumID: tall,
				albumArtist: "Beethoven",
				albumTitle: "a",
				coverArtFileName: "Real",
				discCount: 1,
				discNumber: 1,
				trackNumber: 1,
				title: "",
				artist: "",
				dateAdded: .now,
				releaseDate: nil
			),
			Sim_SongInfo(
				albumID: wide,
				albumArtist: "Beethoven",
				albumTitle: "b",
				coverArtFileName: "wide",
				discCount: 1,
				discNumber: 1,
				trackNumber: 1,
				title: "",
				artist: "",
				dateAdded: .now,
				releaseDate: nil
			),
			Sim_SongInfo(
				albumID: noArtwork,
				albumArtist: "Beethoven",
				albumTitle: "c",
				coverArtFileName: "",
				discCount: 1,
				discNumber: 1,
				trackNumber: 1,
				title: "",
				artist: "",
				dateAdded: .now,
				releaseDate: nil
			),
			
			Sim_SongInfo(
				albumID: khan,
				albumArtist: "Star Trek",
				albumTitle: "Star Trek II",
				coverArtFileName: "Star Trek II",
				discCount: 0,
				discNumber: 0,
				trackNumber: 0,
				title: nil,
				artist: nil,
				dateAdded: .now,
				releaseDate: .now
			),
			Sim_SongInfo(
				albumID: voyage,
				albumArtist: "Star Trek",
				albumTitle: "Star Trek IV",
				coverArtFileName: "Star Trek IV",
				discCount: 1,
				discNumber: 1,
				trackNumber: 3,
				title: "좋은 날",
				artist: "IU",
				dateAdded: .now,
				releaseDate: .now
			),
			
			Sim_SongInfo(
				isCurrentSong: true,
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArtFileName: "Fez",
				discCount: 1,
				discNumber: 1,
				trackNumber: 1,
				title: "Adventure",
				artist: "",
				dateAdded: .now,
				releaseDate: .now
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArtFileName: "Fez",
				discCount: 1,
				discNumber: 1,
				trackNumber: 2,
				title: "Puzzle",
				artist: "",
				dateAdded: .now,
				releaseDate: .now
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArtFileName: "Fez",
				discCount: 1,
				discNumber: 1,
				trackNumber: 3,
				title: "Beyond",
				artist: "",
				dateAdded: .now,
				releaseDate: .now
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArtFileName: "Fez",
				discCount: 1,
				discNumber: 1,
				trackNumber: 4,
				title: "Progress",
				artist: "",
				dateAdded: .now,
				releaseDate: .now
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArtFileName: "Fez",
				discCount: 1,
				discNumber: 1,
				trackNumber: 5,
				title: "Beacon",
				artist: "",
				dateAdded: .now,
				releaseDate: .now
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArtFileName: "Fez",
				discCount: 1,
				discNumber: 1,
				trackNumber: 6,
				title: "Flow",
				artist: "",
				dateAdded: .now,
				releaseDate: .now
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArtFileName: "Fez",
				discCount: 1,
				discNumber: 1,
				trackNumber: 7,
				title: "Formations",
				artist: "",
				dateAdded: .now,
				releaseDate: .now
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArtFileName: "Fez",
				discCount: 1,
				discNumber: 1,
				trackNumber: 8,
				title: "Legend",
				artist: "",
				dateAdded: .now,
				releaseDate: .now
			),
			
			Sim_SongInfo(
				albumID: sonic,
				albumArtist: "Games",
				albumTitle: "Sonic Adventure",
				coverArtFileName: "Sonic Adventure",
				discCount: 1,
				discNumber: 1,
				trackNumber: 900,
				title: "Amazingly few discotheques provide jukeboxes.",
				artist: "Tony Harnell",
				dateAdded: .now,
				releaseDate: .now
			),
		]
	}
	
	static var dict: [SongID: Self] = [:]
	init(
		isCurrentSong: Bool = false,
		albumID: AlbumID,
		albumArtist: String?,
		albumTitle: String?,
		coverArtFileName: String?,
		discCount: Int,
		discNumber: Int,
		trackNumber: Int,
		title: String?,
		artist: String?,
		dateAdded: Date,
		releaseDate: Date?
	) {
		// Memberwise initializer
		self.init(
			albumID: albumID,
			songID: isCurrentSong ? Sim_Global.currentSongID : SongIDDispenser.takeNumber(),
			albumArtistOnDisk: albumArtist,
			albumTitleOnDisk: albumTitle,
			discCountOnDisk: discCount,
			discNumberOnDisk: discNumber,
			trackNumberOnDisk: trackNumber,
			titleOnDisk: title,
			artistOnDisk: artist,
			dateAddedOnDisk: dateAdded,
			releaseDateOnDisk: releaseDate,
			coverArtFileName: coverArtFileName
		)
		
		Self.dict[self.songID] = self
	}
	private enum AlbumIDDispenser {
		private static var nextAvailable = 1
		static func takeNumber() -> AlbumID {
			let result = AlbumID(nextAvailable)
			nextAvailable += 1
			return result
		}
	}
	private enum SongIDDispenser {
		private static var nextAvailable = 1
		static func takeNumber() -> SongID {
			let result = SongID(nextAvailable)
			nextAvailable += 1
			return result
		}
	}
}
#endif
