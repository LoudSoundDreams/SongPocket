//
//  extension MPMediaItem.swift
//  LavaRock
//
//  Created by h on 2021-07-10.
//

import MediaPlayer

extension MPMediaItem {
	
	// Note: Behavior is undefined if you compare with an MPMediaItem from a different album.
	// Verified as of build 154 on iOS 14.7 beta 5.
	final func precedesInSameAlbumInDisplayOrder(_ other: MPMediaItem) -> Bool {
		// Sort by disc number
		// As of iOS 14.7 beta 5, MediaPlayer reports unknown disc numbers as 1, so there's no need to move disc 0 to the end.
		let myDisc = discNumber
		let otherDisc = other.discNumber
		guard myDisc == otherDisc else {
			return myDisc < otherDisc
		}
		
		let myTrack = albumTrackNumber
		let otherTrack = other.albumTrackNumber
		guard myTrack != otherTrack else {
			// Sort by song title
			let myTitle = title ?? ""
			let otherTitle = other.title ?? ""
			// Don't sort Strings by <. That puts all capital letters before all lowercase letters, meaning "Z" comes before "a".
			return myTitle.precedesAlphabeticallyFinderStyle(otherTitle)
		}
		
		// Move unknown track number to the end
		// As of iOS 14.7 beta 5, MediaPlayer reports unknown track numbers as 0. We should move those to the end.
		if otherTrack == 0 {
			return true
		}
		if myTrack == 0 {
			return false
		}
		
		// Sort by track number
		return myTrack < otherTrack
	}
	
}
