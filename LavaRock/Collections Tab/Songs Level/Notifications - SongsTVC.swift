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
			dismiss(animated: true, completion: nil)
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
