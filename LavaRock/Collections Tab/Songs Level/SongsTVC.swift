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
	
	// Variables
	var areSongActionsPresented = false // If we have to refresh to reflect changes in the Apple Music library, and the refresh will change indexedLibraryItems, we'll dismiss this action sheet first.
	
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
		sortOptions = [.trackNumber]
	}
	
	final func refreshNavigationItemTitle() {
		if let containingAlbum = containerOfLibraryItems as? Album {
			title = containingAlbum.titleFormattedOrPlaceholder()
		}
	}
	
}
