//
//  SongMetadatum.swift
//  LavaRock
//
//  Created by h on 2021-12-24.
//

import UIKit
import MediaPlayer

typealias AlbumID = Int64
typealias SongID = Int64

protocol SongMetadatum {
	var albumID: AlbumID { get }
	var songID: SongID { get }
	
	var albumArtistOnDisk: String? { get }
	var albumTitleOnDisk: String? { get }
	
	var discCountOnDisk: Int { get }
	var discNumberOnDisk: Int { get }
	var trackNumberOnDisk: Int { get }
	static var unknownTrackNumber: Int { get }
	
	var titleOnDisk: String? { get }
	var artistOnDisk: String? { get }
	
	var releaseDateOnDisk: Date? { get }
	var dateAddedOnDisk: Date { get }
	
	func coverArt(at size: CGSize) -> UIImage?
}

extension MPMediaItem: SongMetadatum {
	var albumID: AlbumID { AlbumID(bitPattern: albumPersistentID) }
	var songID: SongID { SongID(bitPattern: persistentID) }
	
	// Media Player reports unknown values as …
	
	var albumArtistOnDisk: String? { albumArtist } // … `nil`, as of iOS 14.7 developer beta 5.
	var albumTitleOnDisk: String? { albumTitle } // … `""`, as of iOS 14.7 developer beta 5.
	
	var discCountOnDisk: Int { discCount } // … `0`, as of iOS 15.0 RC.
	var discNumberOnDisk: Int { discNumber } // … `1`, as of iOS 14.7 developer beta 5.
	var trackNumberOnDisk: Int { albumTrackNumber }
	static let unknownTrackNumber = 0 // As of iOS 14.7 developer beta 5.
	
	var titleOnDisk: String? { title } // … we don’t know, because Music for Mac as of version 1.1.5.74 doesn’t allow blank song titles. But that means we shouldn’t need to move unknown song titles to the end.
	var artistOnDisk: String? { artist }
	
	var releaseDateOnDisk: Date? { releaseDate }
	var dateAddedOnDisk: Date { dateAdded }
	
	func coverArt(at size: CGSize) -> UIImage? {
		return artwork?.image(at: size)
	}
}

#if targetEnvironment(simulator)
struct Sim_SongMetadatum: SongMetadatum {
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
	
	let releaseDateOnDisk: Date?
	let dateAddedOnDisk: Date
	
	func coverArt(at size: CGSize) -> UIImage? {
		return nil
	}
}
struct Sim_AlbumIDDispenser {
	private static var sim_nextAvailable = 1
	static func takeNumber() -> AlbumID {
		let result = AlbumID(sim_nextAvailable)
		sim_nextAvailable += 1
		return result
	}
}
private struct Sim_SongIDDispenser {
	private static var sim_nextAvailable = 1
	static func takeNumber() -> SongID {
		let result = SongID(sim_nextAvailable)
		sim_nextAvailable += 1
		return result
	}
}
extension Sim_SongMetadatum {
	static var all: [Self] = []
	
	init(
		albumID: AlbumID,
		albumArtistOnDisk: String?,
		albumTitleOnDisk: String?,
		discCountOnDisk: Int,
		discNumberOnDisk: Int,
		trackNumberOnDisk: Int,
		titleOnDisk: String?,
		artistOnDisk: String?,
		releaseDateOnDisk: Date?,
		dateAddedOnDisk: Date
	) {
		self.init(
			albumID: albumID,
			songID: Sim_SongIDDispenser.takeNumber(),
			albumArtistOnDisk: albumArtistOnDisk,
			albumTitleOnDisk: albumTitleOnDisk,
			discCountOnDisk: discCountOnDisk,
			discNumberOnDisk: discNumberOnDisk,
			trackNumberOnDisk: trackNumberOnDisk,
			titleOnDisk: titleOnDisk,
			artistOnDisk: artistOnDisk,
			releaseDateOnDisk: releaseDateOnDisk,
			dateAddedOnDisk: dateAddedOnDisk)
		
		Self.all.append(self)
	}
}
#endif

struct SongMetadatumPlaceholder {
	static let unknownTitle = "—" // Em dash
}

extension SongMetadatum {
	// MARK: Predicates for Sorting
	
	// Behavior is undefined if you compare with a `SongMetadatum` from the same album.
	// Verified with `MPMediaItem`s as of build 157 on iOS 14.7 developer beta 5.
	func precedesInDefaultOrder(inDifferentAlbum other: SongMetadatum) -> Bool {
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
		guard let otherAlbumArtist = otherAlbumArtist, otherAlbumArtist != "" else {
			return true
		}
		guard let myAlbumArtist = myAlbumArtist, myAlbumArtist != "" else {
			return false
		}
		
		// Sort by album artist
		return myAlbumArtist.precedesAlphabeticallyFinderStyle(otherAlbumArtist)
	}
	
	func precedesInDefaultOrder(inSameAlbum other: SongMetadatum) -> Bool {
		return precedesInDisplayOrder(
			inSameAlbum: other,
			shouldResortToTitle: true)
	}
	
	func precedesForSortOptionTrackNumber(_ other: SongMetadatum) -> Bool {
		return precedesInDisplayOrder(
			inSameAlbum: other,
			shouldResortToTitle: false)
	}
	
	// Behavior is undefined if you compare with a `SongMetadatum` from a different album.
	// Verified with `MPMediaItem`s as of build 154 on iOS 14.7 developer beta 5.
	private func precedesInDisplayOrder(
		inSameAlbum other: SongMetadatum,
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
			// At this point, leave elements in the same order if they both have no release date, or the same release date.
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
	
	// MARK: Formatted Attributes
	
	var shouldShowDiscNumber: Bool {
		if discCountOnDisk >= 2 {
			return true
		} else {
			return discNumberOnDisk >= 2
		}
	}
	
	func discAndTrackNumberFormatted() -> String {
		var result = discNumberFormatted()
		result += LocalizedString.interpunct
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
