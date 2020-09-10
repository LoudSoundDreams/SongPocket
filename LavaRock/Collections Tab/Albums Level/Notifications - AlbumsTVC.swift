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
	override func didSaveChangesFromAppleMusic() {
		if albumMoverClipboard != nil {
			dismiss(animated: true, completion: nil)
		} else {
			super.didSaveChangesFromAppleMusic()
		}
	}
	
	// This is the same as in SongsTVC.
	override func refreshContainerOfData() {
		super.refreshContainerOfData()
		
		refreshNavigationItemTitle()
	}
	
}
