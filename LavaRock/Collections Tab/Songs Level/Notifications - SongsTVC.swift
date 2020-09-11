//
//  Notifications - SongsTVC.swift
//  LavaRock
//
//  Created by h on 2020-09-10.
//

import UIKit

extension SongsTVC {
	
	override func didSaveChangesFromAppleMusic() {
		if isPresentingSongActions {
			dismiss(animated: true, completion: nil) // TO DO: Don't do this unless refreshing to reflect changes in the Apple Music library is going to affect what we have onscreen.
		}
		
		super.didSaveChangesFromAppleMusic()
	}
	
	// This is the same as in AlbumsTVC.
	override func refreshContainerOfData() {
		super.refreshContainerOfData()
		
		refreshNavigationItemTitle()
	}
	
}
