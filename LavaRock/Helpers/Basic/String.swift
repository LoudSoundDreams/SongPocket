//
//  String.swift
//  LavaRock
//
//  Created by h on 2021-04-27.
//

extension String {
	static let SFSpeakerWave = "speaker.wave.2.fill"
	static let SFSpeakerNoWave = "speaker.fill"
	
	static let SFPreviousTrack = "backward.end"
	static let SFRewind = "arrow.counterclockwise.circle"
	static let SFSkipBack10 = "gobackward.10"
	static let SFPlay = "play.circle"
	static let SFPause = "pause.circle"
	static let SFSkipForward10 = "goforward.10"
	static let SFNextTrack = "forward.end"
	
	func truncatedIfLonger(than maxLength: Int) -> String {
		let trimmed = prefix(maxLength - 1)
		if self == trimmed {
			return self
		} else {
			return "\(trimmed)\(LocalizedString.ellipsis)"
		}
	}
	
	// Don’t sort `String`s by `<`. That puts all capital letters before all lowercase letters, meaning “Z” comes before “a”.
	func precedesAlphabeticallyFinderStyle(_ other: Self) -> Bool {
		let comparisonResult = localizedStandardCompare(other) // The comparison method that the Finder uses
		return comparisonResult == .orderedAscending
	}
}
