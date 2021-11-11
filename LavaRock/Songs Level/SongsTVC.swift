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
	NoItemsBackgroundManager
{
	
	// MARK: - Properties
	
	// NoItemsBackgroundManager
	lazy var noItemsBackgroundView = tableView.dequeueReusableCell(withIdentifier: "No Songs Placeholder")
	
	// MARK: - Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		sortOptionsGrouped = [
			[.trackNumber],
			[.reverse],
		]
	}
	
	final override func setUpUI() {
		super.setUpUI()
		
		editingModeToolbarButtons = [
			sortButton, .flexibleSpace(),
			floatToTopButton, .flexibleSpace(),
			sinkToBottomButton,
		]
	}
	
	// MARK: - Refreshing UI
	
	final override func reflectViewModelIsEmpty() {
		let toDelete = tableView.allSections()
		deleteThenExit(sections: toDelete)
	}
	
}
