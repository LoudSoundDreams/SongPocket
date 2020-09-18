//
//  Notifications - AlbumsTVC.swift
//  LavaRock
//
//  Created by h on 2020-09-03.
//

import UIKit
import CoreData

extension AlbumsTVC {
	
	// MARK: - Refreshing Data and Views
	
	override func refreshDataAndViews() {
		if albumMoverClipboard != nil {
			dismiss(animated: true, completion: nil)
			return
		}
		
		super.refreshDataAndViews()
	}
	
	// This is the same as in SongsTVC.
	override func refreshContainerOfData() {
		super.refreshContainerOfData()
		
		refreshNavigationItemTitle()
	}
	
}
