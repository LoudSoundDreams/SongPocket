//
//  SongsTVC.swift
//  LavaRock
//
//  Created by h on 2020-05-04.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import CoreData

final class SongsTVC:
	LibraryTVC,
	NoItemsBackgroundManager
{
	// MARK: - Properties
	
	// NoItemsBackgroundManager
	lazy var noItemsBackgroundView = tableView.dequeueReusableCell(withIdentifier: "No Songs Placeholder")
	
	// State
	var openedAlbum: Album? = nil
	
	// MARK: - Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		sortOptionsGrouped = [
			[.trackNumber],
			[.random, .reverse],
		]
	}
	
	final override func setUpUI() {
		super.setUpUI()
		
		if Enabling.multialbum {
			navigationItem.largeTitleDisplayMode = .never
		}
		
		editingModeToolbarButtons = [
			sortButton, .flexibleSpace(),
			floatToTopButton, .flexibleSpace(),
			sinkToBottomButton,
		]
	}
	
	final override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if let album = openedAlbum {
			openedAlbum = nil
			if let indexPath = (viewModel as? SongsViewModel)?.indexPath(for: album) {
				tableView.scrollToRow(at: indexPath, at: .top, animated: false)
			}
		}
	}
	
	// MARK: - Freshening UI
	
	final override func reflectViewModelIsEmpty() {
		let toDelete = tableView.allSections()
		deleteThenExit(sections: toDelete)
	}
}
