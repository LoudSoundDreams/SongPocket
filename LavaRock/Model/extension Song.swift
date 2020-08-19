//
//  extension Song.swift
//  LavaRock
//
//  Created by h on 2020-08-16.
//

import CoreData
import MediaPlayer

extension Song {
	
	// MARK: Getting Stored Attributes in a Nice Format
	
	// There's a similar method in `extension Album`. Make this generic?
	func titleOrPlaceholder() -> String {
		if
			let storedTitle = title,
			storedTitle != ""
		{
			return storedTitle
		} else {
			return "Unknown Song"
		}
	}
	
	func trackNumberFormatted() -> String {
		if trackNumber == 0 {
			return "•"
		} else {
			return String(trackNumber)
		}
	}
	
}
