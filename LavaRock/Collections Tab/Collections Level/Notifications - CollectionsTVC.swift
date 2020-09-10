//
//  Notifications - CollectionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-09-01.
//

import UIKit
import CoreData

extension CollectionsTVC {
	
	// This is the same as in AlbumsTVC.
	override func didSaveChangesFromAppleMusic() {
		if albumMoverClipboard != nil {
			dismiss(animated: true, completion: nil)
		} else {
			super.didSaveChangesFromAppleMusic()
		}
	}
	
}
