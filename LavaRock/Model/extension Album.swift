//
//  extension Album.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit
import CoreData
import ImageIO

extension Album {
	
	// There's a similar method in `extension Song`. Make this generic?
	func titleOrPlaceholder() -> String {
		if
			let storedTitle = title,
			storedTitle != ""
		{
			return storedTitle
		} else {
			return AlbumsTVC.unknownAlbumTitlePlaceholderText
		}
	}
	
	func releaseDateFormatted() -> String? {
		if let date = releaseDateEstimate {
			let dateFormatter = DateFormatter()
			
			// Insert date formatter options
////			dateFormatter.locale = Locale.current
//			dateFormatter.locale = Locale(identifier: "en_US_POSIX")
//			dateFormatter.dateFormat = "yyyy-MM-dd"
//			dateFormatter.timeZone = TimeZone.current// TimeZone(secondsFromGMT: 0)
////			dateFormatter.setLocalizedDateFormatFromTemplate("yyyy-MM-dd")
			
			dateFormatter.dateStyle = .medium
			dateFormatter.timeStyle = .none
			
			return dateFormatter.string(from: date)
		} else {
			return nil
		}
	}
	
}
