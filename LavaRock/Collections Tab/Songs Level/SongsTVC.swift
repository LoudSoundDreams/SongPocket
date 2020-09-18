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
	
	// "Constants"
	var currentSongIndicatorImage: UIImage? {
		if
			let playerController = playerController,
			playerController.playbackState == .playing // There are many playback states; only show the "playing" icon when the player controller is playing. Otherwise, show the "not playing" icon.
		{
			return UIImage(systemName: "speaker.wave.2.fill")
		} else {
			return UIImage(systemName: "speaker.fill")
		}
	}
	
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
		toolbarButtonsEditingModeOnly = [
			sortButton,
			flexibleSpaceBarButtonItem,
			floatToTopButton,
			flexibleSpaceBarButtonItem,
			sinkToBottomButton
		]
		sortOptions = ["Track Number"]
	}
	
	final func refreshNavigationItemTitle() {
		if let containingAlbum = containerOfData as? Album {
			title = containingAlbum.titleFormattedOrPlaceholder()
		}
	}
	
}
