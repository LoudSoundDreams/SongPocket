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
	
	// MARK: - Sorting
	
	// Note: Behavior is undefined if you compare with an MPMediaItem from a different album.
	// Verified as of build 154 on iOS 14.7 beta 5.
	final func precedesInSameAlbumInDisplayOrder(_ other: MPMediaItem) -> Bool {
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
			// Don't sort Strings by <. That puts all capital letters before all lowercase letters, meaning "Z" comes before "a".
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
