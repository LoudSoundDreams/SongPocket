//
//  SongInfo.swift
//  LavaRock
//
//  Created by h on 2021-12-24.
//

import MediaPlayer
import UIKit
import OSLog

typealias AlbumID = Int64
typealias SongID = Int64

protocol SongInfo {
	var albumID: AlbumID { get }
	var songID: SongID { get }
	
	var composerOnDisk: String { get }
	var albumArtistOnDisk: String? { get }
	var albumTitleOnDisk: String? { get }
	var discCountOnDisk: Int { get }
	var discNumberOnDisk: Int { get }
	var trackNumberOnDisk: Int { get }
	static var unknownTrackNumber: Int { get }
	var titleOnDisk: String? { get }
	var artistOnDisk: String? { get }
	var dateAddedOnDisk: Date { get }
	var releaseDateOnDisk: Date? { get }
	func coverArt(largerThanOrEqualToSizeInPoints sizeInPoints: CGSize) -> UIImage?
}
enum SongInfoPlaceholder {
	static let unknownTitle = "—" // Em dash
}
extension SongInfo {
	
	// MARK: Predicates
	
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
				return true // Maybe we could go further with some other criterion
			}
			
			// Move unknown album title to end
			guard otherAlbumTitle != "", let otherAlbumTitle = otherAlbumTitle else {
				return true
			}
			guard myAlbumTitle != "", let myAlbumTitle = myAlbumTitle else {
				return false
			}
			
			// Sort by album title
			return myAlbumTitle.precedesAlphabeticallyFinderStyle(otherAlbumTitle)
		}
		
		// Move unknown album artist to end
		guard let otherAlbumArtist, otherAlbumArtist != "" else {
			return true
		}
		guard let myAlbumArtist, myAlbumArtist != "" else {
			return false
		}
		
		// Sort by album artist
		return myAlbumArtist.precedesAlphabeticallyFinderStyle(otherAlbumArtist)
	}
	
	func precedesInDefaultOrder(inSameAlbum other: SongInfo) -> Bool {
		return precedesInDisplayOrder(
			inSameAlbum: other,
			shouldResortToTitle: true)
	}
	
	func precedesByTrackNumber(_ other: SongInfo) -> Bool {
		return precedesInDisplayOrder(
			inSameAlbum: other,
			shouldResortToTitle: false)
	}
	
	// Behavior is undefined if you compare with a `SongInfo` from a different album.
	private func precedesInDisplayOrder(
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
				return myTitle.precedesAlphabeticallyFinderStyle(otherTitle)
			}
		} else {
			// At this point, leave elements in the same order if they both have no track number, or the same track number.
			// However, as of iOS 14.7, when using `sorted(by:)`, returning `true` here doesn’t always keep the elements in the same order. Call this method in `sortedMaintainingOrderWhen` to guarantee stable sorting.
			guard myTrack != otherTrack else {
				return true
			}
		}
		
		// Move unknown track number to the end
		guard otherTrack != type(of: other).unknownTrackNumber else {
			return true
		}
		guard myTrack != Self.unknownTrackNumber else {
			return false
		}
		
		// Sort by track number
		return myTrack < otherTrack
	}
	
	// MARK: Formatted attributes
	
	var shouldShowDiscNumber: Bool {
		if discCountOnDisk >= 2 {
			return true
		} else {
			return discNumberOnDisk >= 2
		}
	}
	
	func discAndTrackNumberFormatted() -> String {
		var result = discNumberFormatted()
		result += LRString.interpunct
		if let trackNumber = trackNumberFormattedOptional() {
			result += trackNumber
		}
		return result
	}
	
	func discNumberFormatted() -> String {
		return String(discNumberOnDisk)
	}
	
	func trackNumberFormattedOptional() -> String? {
		guard trackNumberOnDisk != Self.unknownTrackNumber else {
			return nil
		}
		return String(trackNumberOnDisk)
	}
}

// MARK: - Media Player

extension MPMediaItem: SongInfo {
	final var albumID: AlbumID { AlbumID(bitPattern: albumPersistentID) }
	final var songID: SongID { SongID(bitPattern: persistentID) }
	
	// Media Player reports unknown values as…
	final var composerOnDisk: String { composer ?? "" }
	final var albumArtistOnDisk: String? { albumArtist } // `nil`, as of iOS 14.7 developer beta 5.
	final var albumTitleOnDisk: String? { albumTitle } // `""`, as of iOS 14.7 developer beta 5.
	final var discCountOnDisk: Int { discCount } // `0`, as of iOS 15.0 RC.
	final var discNumberOnDisk: Int { discNumber } // `1`, as of iOS 14.7 developer beta 5.
	final var trackNumberOnDisk: Int { albumTrackNumber }
	static let unknownTrackNumber = 0 // As of iOS 14.7 developer beta 5.
	final var titleOnDisk: String? { title } // …we don’t know, because Apple Music for Mac as of version 1.1.5.74 doesn’t allow blank song titles. But that means we shouldn’t need to move unknown song titles to the end.
	final var artistOnDisk: String? { artist }
	final var dateAddedOnDisk: Date { dateAdded }
	final var releaseDateOnDisk: Date? { releaseDate }
	final func coverArt(
		largerThanOrEqualToSizeInPoints sizeInPoints: CGSize
	) -> UIImage? {
		let signposter = OSSignposter()
		let state = signposter.beginInterval("Draw cover art")
		defer {
			signposter.endInterval("Draw cover art", state)
		}
		return artwork?.image(at: sizeInPoints)
	}
}

// MARK: - Simulator

#if targetEnvironment(simulator)
struct Sim_SongInfo: SongInfo {
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
		
		let walpurgis = 1
		return [
			Sim_SongInfo(
				albumID: walpurgis,
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
				albumID: walpurgis,
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
				albumID: 2,
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
				albumID: 3,
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
		albumID: Int,
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
			albumID: AlbumID(albumID),
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
