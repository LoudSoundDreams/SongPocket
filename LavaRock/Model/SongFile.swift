//
//  SongFile.swift
//  LavaRock
//
//  Created by h on 2021-12-24.
//

import UIKit

typealias AlbumFolderID = Int64
typealias SongFileID = Int64

protocol SongFile {
	var albumFolderID: AlbumFolderID { get }
	var fileID: SongFileID { get }
	
	var albumArtistOnDisk: String? { get }
	var albumTitleOnDisk: String? { get }
	var discCountOnDisk: Int { get }
	var discNumberOnDisk: Int { get }
	var trackNumberOnDisk: Int { get }
	var titleOnDisk: String? { get }
	var artistOnDisk: String? { get }
	var releaseDateOnDisk: Date? { get }
	var dateAddedOnDisk: Date { get }
	
	func artworkImage(at size: CGSize) -> UIImage?
}

extension SongFile {
	// MARK: Predicates for Sorting
	
	// Behavior is undefined if you compare with a `SongFile` from the same album.
	// Verified with `MPMediaItem`s as of build 157 on iOS 14.7 developer beta 5.
	func precedesInDefaultOrder(inDifferentAlbum other: SongFile) -> Bool {
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
	
	func precedesInDefaultOrder(inSameAlbum other: SongFile) -> Bool {
		return precedesInDisplayOrder(
			inSameAlbum: other,
			shouldResortToTitle: true)
	}
	
	func precedesForSortOptionTrackNumber(_ other: SongFile) -> Bool {
		return precedesInDisplayOrder(
			inSameAlbum: other,
			shouldResortToTitle: false)
	}
	
	// Behavior is undefined if you compare with a `SongFile` from a different album.
	// Verified with `MPMediaItem`s as of build 154 on iOS 14.7 developer beta 5.
	private func precedesInDisplayOrder(
		inSameAlbum other: SongFile,
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
			// However, as of iOS 14.7, when using `sorted(by:)`, returning `true` here doesn't always keep the elements in the same order. Call this method in `sortedMaintainingOrderWhen` to guarantee stable sorting.
			guard myTrack != otherTrack else {
				return true
			}
		}
		
		// Move unknown track number to the end
		guard otherTrack != SongFileExtras.unknownTrackNumber else {
			return true
		}
		guard myTrack != SongFileExtras.unknownTrackNumber else {
			return false
		}
		
		// Sort by track number
		return myTrack < otherTrack
	}
	
	// MARK: Formatted Attributes
	
	func discAndTrackNumberFormatted() -> String {
		let trackNumberString: String = {
			guard trackNumberOnDisk != SongFileExtras.unknownTrackNumber else {
				return ""
			}
			return String(trackNumberOnDisk)
		}()
		return "\(discNumberOnDisk)·\(trackNumberString)" // That’s an interpunct.
	}
	
	func trackNumberFormatted() -> String {
		guard trackNumberOnDisk != SongFileExtras.unknownTrackNumber else {
			return SongFileExtras.unknownTrackNumberPlaceholder
		}
		return String(trackNumberOnDisk)
	}
}

struct SongFileExtras {
	private init() {}

	static let unknownTitlePlaceholder = "—" // Em dash
	static let unknownTrackNumber = 0
	static let unknownTrackNumberPlaceholder = "‒" // Figure dash
}
