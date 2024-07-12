// 2021-12-24

import UIKit

typealias AlbumID = Int64 // TO DO: Prevent confusion with `Album.index`
typealias SongID = Int64 // TO DO: Prevent confusion with `Song.index`

protocol SongInfo {
	var albumID: AlbumID { get }
	var songID: SongID { get }
	
	var albumArtistOnDisk: String? { get } // TO DO: Delete
	var albumTitleOnDisk: String? { get } // TO DO: Delete
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
	
	// Behavior is undefined if you compare with a `SongInfo` from the same album.
	func precedesInDefaultOrder(inDifferentAlbum other: SongInfo) -> Bool {
		let myAlbumArtist = albumArtistOnDisk
		let otherAlbumArtist = other.albumArtistOnDisk
		// Either can be `nil`
		
		guard myAlbumArtist != otherAlbumArtist else {
			let myAlbumTitle = albumTitleOnDisk
			let otherAlbumTitle = other.albumTitleOnDisk
			// Either can be `nil`
			
			guard myAlbumTitle != otherAlbumTitle else {
				return true
				// Maybe we could go further with some other criterion
			}
			
			// Move unknown album title to end
			guard otherAlbumTitle != "", let otherAlbumTitle = otherAlbumTitle else { return true }
			guard myAlbumTitle != "", let myAlbumTitle = myAlbumTitle else { return false }
			
			return myAlbumTitle.precedesInFinder(otherAlbumTitle)
		}
		
		// Move unknown album artist to end
		guard let otherAlbumArtist, otherAlbumArtist != "" else { return true }
		guard let myAlbumArtist, myAlbumArtist != "" else { return false }
		
		return myAlbumArtist.precedesInFinder(otherAlbumArtist)
	}
	
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
	
	var shouldShowDiscNumber: Bool {
		return discCountOnDisk >= 2 || discNumberOnDisk >= 2
	}
	func discAndTrackFormatted() -> String {
		return "\(discNumberOnDisk)\(InterfaceText.interpunct)\(trackFormatted())"
	}
	func trackFormatted() -> String {
		guard trackNumberOnDisk != Self.unknownTrackNumber else { return InterfaceText.octothorpe }
		return String(trackNumberOnDisk)
	}
}

// MARK: - Apple Music

import MediaPlayer
extension MPMediaItem: SongInfo {
	final var albumID: AlbumID { AlbumID(bitPattern: albumPersistentID) }
	final var songID: SongID { SongID(bitPattern: persistentID) }
	
	// Media Player reports unknown values as…
	final var albumArtistOnDisk: String? { albumArtist } // `nil`, as of iOS 14.7 developer beta 5
	final var albumTitleOnDisk: String? { albumTitle } // `""`, as of iOS 14.7 developer beta 5
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
import UIKit

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
	
	// Not protocol requirements
	let releaseDate: Date?
	let coverArtFileName: String
}
extension Sim_SongInfo: Equatable {}

private extension Date {
	// "1984-01-24"
	static func lateNight(iso8601_10Char: String) -> Self {
		return try! Self("\(iso8601_10Char)T23:59:59Z", strategy: .iso8601)
	}
}

extension Sim_SongInfo {
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
	
	static var current: Self? = nil
	init(
		asCurrent: Bool = false,
		albumID: AlbumID,
		albumArtist: String?,
		albumTitle: String?,
		coverArt: String,
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
			songID: SongIDDispenser.takeNumber(),
			albumArtistOnDisk: albumArtist,
			albumTitleOnDisk: albumTitle,
			discCountOnDisk: discCount,
			discNumberOnDisk: discNumber,
			trackNumberOnDisk: track,
			titleOnDisk: title,
			artistOnDisk: by,
			dateAddedOnDisk: added,
			releaseDate: {
				guard let released else { return nil }
				return Date.lateNight(iso8601_10Char: released)
			}(),
			coverArtFileName: coverArt)
		if asCurrent { Self.current = self }
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
				asCurrent: true,
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
}
#endif
