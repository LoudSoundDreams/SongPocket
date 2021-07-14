//
//  extension MPMediaItem.swift
//  LavaRock
//
//  Created by h on 2021-07-10.
//

import MediaPlayer

extension MPMediaItem {
	
	// MARK: - Properties
	
	// As of iOS 14.7 beta 5, MediaPlayer reports unknown track numbers as 0.
	private static let unknownTrackNumber = 0
	
	// MARK: - Predicates for Sorting
	
	// Note: Behavior is undefined if you compare with an MPMediaItem from the same album.
	// Verified as of build 157 on iOS 14.7 beta 5.
	final func precedesForImporterDisplayOrderOfAlbums(inDifferentAlbum other: MPMediaItem) -> Bool {
		let myArtist = albumArtist
		let otherArtist = other.albumArtist
		// Either can be nil
		
		guard myArtist != otherArtist else {
			let myTitle = albumTitle
			let otherTitle = other.albumTitle
			// Either can be nil
			
			guard myTitle != otherTitle else {
				return true // Maybe we could go further with some other criterion
			}
			
			// Move unknown album title to end
			// As of iOS 14.7 beta 5, MediaPlayer reports unknown album titles as "".
			guard otherTitle != "", let otherTitle = otherTitle else {
				return true
			}
			guard myTitle != "", let myTitle = myTitle else {
				return false
			}
			
			// Sort by album title
			return myTitle.precedesAlphabeticallyFinderStyle(otherTitle)
		}
		
		// Move unknown album artist to end
		// As of iOS 14.7 beta 5, MediaPlayer reports unknown album artists as nil.
		guard let otherArtist = otherArtist, otherArtist != "" else {
			return true
		}
		guard let myArtist = myArtist, myArtist != "" else {
			return false
		}
		
		// Sort by album artist
		return myArtist.precedesAlphabeticallyFinderStyle(otherArtist)
	}
	
	// Note: Behavior is undefined if you compare with an MPMediaItem from a different album.
	// Verified as of build 154 on iOS 14.7 beta 5.
	final func precedesForImporterDisplayOrderOfSongs(inSameAlbum other: MPMediaItem) -> Bool {
		// Sort by disc number
		// Music for Mac as of version 1.1.5.74 changes disc number 0 to blank, so we shouldn't need to move disc 0 to the end.
		// Note: As of iOS 14.7 beta 5, MediaPlayer reports unknown disc numbers as 1.
		let myDisc = discNumber
		let otherDisc = other.discNumber
		guard myDisc == otherDisc else {
			return myDisc < otherDisc
		}
		
		let myTrack = albumTrackNumber
		let otherTrack = other.albumTrackNumber
		
		guard myTrack != otherTrack else {
			// Sort by song title
			// Music for Mac as of version 1.1.5.74 doesn't allow blank song titles, so we shouldn't need to move unknown song titles to the end.
			// Note: We don't know whether MediaPlayer would report unknown song titles as nil or "".
			let myTitle = title ?? ""
			let otherTitle = other.title ?? ""
			return myTitle.precedesAlphabeticallyFinderStyle(otherTitle)
		}
		
		// Move unknown track number to the end
		guard otherTrack != Self.unknownTrackNumber else {
			return true
		}
		guard myTrack != Self.unknownTrackNumber else {
			return false
		}
		
		// Sort by track number
		return myTrack < otherTrack
	}
	
	final func precedesForSortOptionTrackNumber(inSameAlbum other: MPMediaItem) -> Bool {
		// Sort by disc number
		let myDisc = discNumber
		let otherDisc = other.discNumber
		guard myDisc == otherDisc else {
			return myDisc < otherDisc
		}
		
		let myTrack = albumTrackNumber
		let otherTrack = other.albumTrackNumber
		
		// At this point, leave MPMediaItems in the same order if they have the same track number.
		// However, as of iOS 14.7, when using sorted(by:), returning `true` in the closure doesn't always keep the elements in the same order.
		// Use sortedMaintainingOrderWhen(areEqual:areInOrder:) to guarantee stable sorting.
//		guard myTrack != otherTrack else {
//			return true
//		}
		
		// Move unknown track number to the end
		guard otherTrack != Self.unknownTrackNumber else {
			return true
		}
		guard myTrack != Self.unknownTrackNumber else {
			return false
		}
		
		// Sort by track number
		return myTrack < otherTrack
	}
	
	// MARK: - Formatted Attributes
	
	static let placeholderTitle = "—" // Em dash
	static let placeholderTrackNumber = "‒" // Figure dash
	
	final func trackNumberFormatted(includeDisc: Bool) -> String {
		guard includeDisc else {
			// Don't include disc number
			if albumTrackNumber == Self.unknownTrackNumber {
				return Self.placeholderTrackNumber
			} else {
				return String(albumTrackNumber)
			}
		}

		// Include disc number
		let discNumberText = String(discNumber)
		let trackNumberText: String = {
			if albumTrackNumber == Self.unknownTrackNumber {
				return ""
			} else {
				return String(albumTrackNumber)
			}
		}()
		return discNumberText + "-" /*hyphen*/ + trackNumberText
	}
	
}
