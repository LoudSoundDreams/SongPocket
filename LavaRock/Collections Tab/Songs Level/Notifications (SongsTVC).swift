//
//  Notifications (SongsTVC).swift
//  LavaRock
//
//  Created by h on 2020-09-02.
//

import UIKit
import CoreData

extension SongsTVC {
	
	override func deleteFromView(_ items: [NSManagedObject]) {
		print("")
		for item in items {
			let song = item as! Song
			print("We need to delete the song \(song) from this view.")
		}
	}
	
	override func refreshInView(_ items: [NSManagedObject]) {
		print("")
		for item in items {
			let song = item as! Song
			print("We need to refresh the song \(song.titleFormattedOrPlaceholder()) in this view.")
		}
	}
	
}
