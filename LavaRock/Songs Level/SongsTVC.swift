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

final class SongsTVC: LibraryTVC {
	
	// MARK: - Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		sortOptionGroups = [
			[.trackNumber],
			[.reverse]
		]
		
		numberOfRowsInSectionAboveLibraryItems = 2
	}
	
	// MARK: Setting Up UI
	
	final override func setUpUI() {
		super.setUpUI()
		
		bottomButtonsInEditingMode = [
//			.flexibleSpac3(),
			
			sortButton,
			.flexibleSpac3(),
			
//			moveToTopOrBottomButton,
			floatToTopButton,
			.flexibleSpac3(),
			sinkToBottomButton,
		]
	}
	
	final override func refreshNavigationItemTitle() {
		guard let containingAlbum = sectionOfLibraryItems.container as? Album else { return }
		title = containingAlbum.titleFormattedOrPlaceholder()
	}
	
}
