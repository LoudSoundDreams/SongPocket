//
//  Notifications - SongsTVC.swift
//  LavaRock
//
//  Created by h on 2020-09-10.
//

import UIKit

extension SongsTVC {
	
	override func refreshDataAndViews() {
		if areSongActionsPresented {
			dismiss(animated: true, completion: nil) // TO DO: Don't do this unless refreshing to reflect changes in the Apple Music library is going to affect what we have onscreen.
			areSongActionsPresented = false
		}
		
		super.refreshDataAndViews()
	}
	
	// This is the same as in AlbumsTVC.
	override func refreshContainerOfData() {
		super.refreshContainerOfData()
		
		refreshNavigationItemTitle()
	}
	
}
