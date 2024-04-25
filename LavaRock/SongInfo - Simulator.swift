// 2023-08-08

#if targetEnvironment(simulator)
import UIKit

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
	static let unknownTrackNumber = 0
	let titleOnDisk: String?
	let artistOnDisk: String?
	let dateAddedOnDisk: Date
	let releaseDateOnDisk: Date?
	func coverArt(atLeastInPoints: CGSize) -> UIImage? {
		guard let fileName = coverArtFileName else { return nil }
		return UIImage(named: fileName)
	}
	private let coverArtFileName: String?
}
extension Sim_SongInfo {
	init(
		isCurrentSong: Bool = false,
		albumID: AlbumID,
		albumArtist: String?,
		albumTitle: String?,
		coverArt: String?,
		discCount: Int,
		discNumber: Int,
		track: Int,
		title: String?,
		by: String? = nil,
		added: Date,
		released: String? = nil
	) {
		self.init(
			albumID: albumID,
			songID: isCurrentSong ? Sim_Global.currentSongID : SongIDDispenser.takeNumber(),
			albumArtistOnDisk: albumArtist,
			albumTitleOnDisk: albumTitle,
			discCountOnDisk: discCount,
			discNumberOnDisk: discNumber,
			trackNumberOnDisk: track,
			titleOnDisk: title,
			artistOnDisk: by,
			dateAddedOnDisk: added,
			releaseDateOnDisk: {
				guard let released else { return nil }
				return Date.lateNight(iso8601_10Char: released)
			}(),
			coverArtFileName: coverArt)
	}
	static var everyInfo: [SongID: Self] = {
		var result: [SongID: Self] = [:]
//		return result
		
		let tall = AlbumIDDispenser.takeNumber()
		let wide = AlbumIDDispenser.takeNumber()
		let noArtwork = AlbumIDDispenser.takeNumber()
		let trek2 = AlbumIDDispenser.takeNumber()
		let trek4 = AlbumIDDispenser.takeNumber()
		let fez = AlbumIDDispenser.takeNumber()
		let sonic = AlbumIDDispenser.takeNumber()
		
		let fezReleased = "2012-04-20"
		
		[
			Sim_SongInfo(
				albumID: tall,
				albumArtist: "Beethoven",
				albumTitle: "a",
				coverArt: "Real",
				discCount: 1,
				discNumber: 1,
				track: 1,
				title: "",
				by: "",
				added: .now,
				released: nil
			),
			Sim_SongInfo(
				albumID: wide,
				albumArtist: "Beethoven",
				albumTitle: "b",
				coverArt: "wide",
				discCount: 1,
				discNumber: 1,
				track: 1,
				title: "",
				by: "",
				added: .now,
				released: nil
			),
			Sim_SongInfo(
				albumID: noArtwork,
				albumArtist: "Beethoven",
				albumTitle: "c",
				coverArt: "",
				discCount: 1,
				discNumber: 1,
				track: 1,
				title: "",
				by: "",
				added: .now,
				released: nil
			),
			
			Sim_SongInfo(
				albumID: trek2,
				albumArtist: "Star Trek",
				albumTitle: "Star Trek II",
				coverArt: "Star Trek II",
				discCount: 0,
				discNumber: 0,
				track: 0,
				title: nil,
				added: .now,
				released: "1982-06-04"
			),
			Sim_SongInfo(
				albumID: trek4,
				albumArtist: "Star Trek",
				albumTitle: "Star Trek IV",
				coverArt: "Star Trek IV",
				discCount: 1,
				discNumber: 1,
				track: 3,
				title: "좋은 날",
				by: "IU",
				added: .now,
				released: "1986-11-26"
			),
			
			Sim_SongInfo(
				isCurrentSong: true,
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArt: "Fez",
				discCount: 1,
				discNumber: 1,
				track: 1,
				title: "Adventure",
				added: .now,
				released: fezReleased
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArt: "Fez",
				discCount: 1,
				discNumber: 1,
				track: 2,
				title: "Puzzle",
				added: .now,
				released: fezReleased
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArt: "Fez",
				discCount: 1,
				discNumber: 1,
				track: 3,
				title: "Beyond",
				added: .now,
				released: fezReleased
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArt: "Fez",
				discCount: 1,
				discNumber: 1,
				track: 4,
				title: "Progress",
				added: .now,
				released: fezReleased
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArt: "Fez",
				discCount: 1,
				discNumber: 1,
				track: 5,
				title: "Beacon",
				added: .now,
				released: fezReleased
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArt: "Fez",
				discCount: 1,
				discNumber: 1,
				track: 6,
				title: "Flow",
				added: .now,
				released: fezReleased
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArt: "Fez",
				discCount: 1,
				discNumber: 1,
				track: 7,
				title: "Formations",
				added: .now,
				released: fezReleased
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArt: "Fez",
				discCount: 1,
				discNumber: 1,
				track: 8,
				title: "Legend",
				added: .now,
				released: fezReleased
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArt: "Fez",
				discCount: 1,
				discNumber: 1,
				track: 9,
				title: "Compass",
				added: .now,
				released: fezReleased
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArt: "Fez",
				discCount: 1,
				discNumber: 1,
				track: 10,
				title: "Forgotten",
				added: .now,
				released: fezReleased
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArt: "Fez",
				discCount: 1,
				discNumber: 1,
				track: 11,
				title: "Sync",
				added: .now,
				released: fezReleased
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArt: "Fez",
				discCount: 1,
				discNumber: 1,
				track: 12,
				title: "Glitch",
				added: .now,
				released: fezReleased
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArt: "Fez",
				discCount: 1,
				discNumber: 1,
				track: 13,
				title: "Fear",
				added: .now,
				released: fezReleased
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArt: "Fez",
				discCount: 1,
				discNumber: 1,
				track: 14,
				title: "Spirit",
				added: .now,
				released: fezReleased
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArt: "Fez",
				discCount: 1,
				discNumber: 1,
				track: 15,
				title: "Nature",
				added: .now,
				released: fezReleased
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArt: "Fez",
				discCount: 1,
				discNumber: 1,
				track: 16,
				title: "Knowledge",
				added: .now,
				released: fezReleased
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArt: "Fez",
				discCount: 1,
				discNumber: 1,
				track: 17,
				title: "Death",
				added: .now,
				released: fezReleased
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArt: "Fez",
				discCount: 1,
				discNumber: 1,
				track: 18,
				title: "Memory",
				added: .now,
				released: fezReleased
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArt: "Fez",
				discCount: 1,
				discNumber: 1,
				track: 19,
				title: "Pressure",
				added: .now,
				released: fezReleased
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArt: "Fez",
				discCount: 1,
				discNumber: 1,
				track: 20,
				title: "Nocturne",
				added: .now,
				released: fezReleased
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArt: "Fez",
				discCount: 1,
				discNumber: 1,
				track: 21,
				title: "Age",
				added: .now,
				released: fezReleased
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArt: "Fez",
				discCount: 1,
				discNumber: 1,
				track: 22,
				title: "Majesty",
				added: .now,
				released: fezReleased
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArt: "Fez",
				discCount: 1,
				discNumber: 1,
				track: 23,
				title: "Continuum",
				added: .now,
				released: fezReleased
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArt: "Fez",
				discCount: 1,
				discNumber: 1,
				track: 24,
				title: "Home",
				added: .now,
				released: fezReleased
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArt: "Fez",
				discCount: 1,
				discNumber: 1,
				track: 25,
				title: "Reflection",
				added: .now,
				released: fezReleased
			),
			Sim_SongInfo(
				albumID: fez,
				albumArtist: "Disasterpeace",
				albumTitle: "Fez",
				coverArt: "Fez",
				discCount: 1,
				discNumber: 1,
				track: 26,
				title: "Love",
				added: .now,
				released: fezReleased
			),
			
			Sim_SongInfo(
				albumID: sonic,
				albumArtist: "Games",
				albumTitle: "Sonic Adventure",
				coverArt: "Sonic Adventure",
				discCount: 1,
				discNumber: 1,
				track: 900,
				title: "Amazingly few discotheques provide jukeboxes.",
				by: "Tony Harnell",
				added: .now,
				released: "1999-01-20"
			),
		].forEach { result[$0.songID] = $0 }
		return result
	}()
	
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
private extension Date {
	// "1984-01-24"
	static func lateNight(iso8601_10Char: String) -> Self {
		return try! Self("\(iso8601_10Char)T23:59:59Z", strategy: .iso8601)
	}
}
#endif
