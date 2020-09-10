//
//  Notifications - AlbumsTVC.swift
//  LavaRock
//
//  Created by h on 2020-09-03.
//

import UIKit
import CoreData

extension AlbumsTVC {
	
	// This is the same as in CollectionsTVC.
	override func willSaveChangesFromAppleMusicLibrary() {
		if albumMoverClipboard != nil {
			dismiss(animated: true, completion: nil)
		} else {
			super.willSaveChangesFromAppleMusicLibrary()
		}
	}
	
}
