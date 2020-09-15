//
//  SongsTVC.swift
//  LavaRock
//
//  Created by h on 2020-05-04.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import CoreData
import MediaPlayer

final class SongsTVC:
	LibraryTVC,
	NavigationItemTitleCustomizer
{
	
	// MARK: - Properties
	
	// Constants
	let playerController = MPMusicPlayerController.systemMusicPlayer
	
	// Variables
	var areSongActionsPresented = false // If we have to refresh to reflect changes in the Apple Music library, we'll dismiss this action sheet first.
	
	// MARK: - Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		coreDataEntityName = "Song"
		numberOfRowsAboveIndexedLibraryItems = 2
	}
	
	// MARK: Setting Up UI
	
	override func setUpUI() {
		super.setUpUI()
		
		refreshNavigationItemTitle()
		navigationItemButtonsEditingModeOnly = [floatToTopButton, sortButton]
		sortOptions = ["Track Number"]
	}
	
	func refreshNavigationItemTitle() {
		if let containingAlbum = containerOfData as? Album {
			title = containingAlbum.titleFormattedOrPlaceholder()
		}
	}
	
}
