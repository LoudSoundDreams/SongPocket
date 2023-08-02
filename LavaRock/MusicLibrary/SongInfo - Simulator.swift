//
//  SongInfo - Simulator.swift
//  LavaRock
//
//  Created by h on 2022-06-30.
//

#if targetEnvironment(simulator)
import MediaPlayer
import OSLog

struct Sim_SongInfo: SongInfo {
	// `SongInfo`
	
	let albumID: AlbumID
	let songID: SongID
	
	let composerOnDisk: String
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
	
	func coverArt(
		largerThanOrEqualToSizeInPoints sizeInPoints: CGSize
	) -> UIImage? {
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
		if Enabling.sim_emptyLibrary {
			return []
		}
		
		let walpurgisNightAlbumID = Sim_AlbumIDDispenser.takeNumber()
		return [
			Sim_SongInfo(
				albumID: walpurgisNightAlbumID,
				composer: "FRANTS",
				albumArtist: "GFriend",
				albumTitle: "回:Walpurgis Night",
				coverArtFileName: "Walpurgis Night",
				discCount: 2,
				discNumber: 1,
				trackNumber: 1,
				title: "Amazingly few discotheques provide jukeboxes.",
				artist: "Five Boxing Wizards",
				dateAdded: .now,
				releaseDate: .now
			),
			Sim_SongInfo(
				albumID: walpurgisNightAlbumID,
				composer: "노주환 & 이원종",
				albumArtist: "GFriend",
				albumTitle: "回:Walpurgis Night",
				coverArtFileName: "Walpurgis Night",
				discCount: 1,
				discNumber: 1,
				trackNumber: 900,
				title: "Amazingly few discotheques provide jukeboxes. The five boxing wizards jump quickly. Pack my box with five dozen liquor jugs. The quick brown fox jumps over the lazy dog.",
				artist: "GFriend",
				dateAdded: .now,
				releaseDate: .now
			),
			Sim_SongInfo(
				albumID: Sim_AlbumIDDispenser.takeNumber(),
				composer: "",
				albumArtist: nil,
				albumTitle: nil,
				coverArtFileName: "Planetary Pieces",
				discCount: 0,
				discNumber: 0,
				trackNumber: 0,
				title: nil,
				artist: nil,
				dateAdded: .now,
				releaseDate: nil
			),
			Sim_SongInfo(
				albumID: Sim_AlbumIDDispenser.takeNumber(),
				composer: "이민수",
				albumArtist: "IU",
				albumTitle: "Real",
				coverArtFileName: "Real",
				discCount: 1,
				discNumber: 1,
				trackNumber: 3,
				title: "좋은 날",
				artist: "IU",
				dateAdded: .now,
				releaseDate: nil
			),
		]
	}
	
	static var dict: [SongID: Self] = [:]
	init(
		albumID: AlbumID,
		composer: String,
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
			songID: Sim_SongIDDispenser.takeNumber(),
			composerOnDisk: composer,
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
	
	private enum Sim_AlbumIDDispenser {
		private static var nextAvailable = 1
		static func takeNumber() -> AlbumID {
			let result = AlbumID(nextAvailable)
			nextAvailable += 1
			return result
		}
	}
	private enum Sim_SongIDDispenser {
		private static var nextAvailable = 1
		static func takeNumber() -> SongID {
			let result = SongID(nextAvailable)
			nextAvailable += 1
			return result
		}
	}
}
#endif
