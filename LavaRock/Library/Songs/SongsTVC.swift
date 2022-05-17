//
//  SongsTVC.swift
//  LavaRock
//
//  Created by h on 2020-05-04.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit

final class SongsTVC:
	LibraryTVC,
	NoItemsBackgroundManager
{
	// MARK: - Properties
	
	// `NoItemsBackgroundManager`
	lazy var noItemsBackgroundView = tableView.dequeueReusableCell(withIdentifier: "No Songs Placeholder")
	
	// State
	var openedAlbum: Album? = nil
	var willPlayLaterAlertIsPresented = false
	
	// MARK: - Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		sortOptionsGrouped = [
			[.trackNumber],
			[.shuffle, .reverse],
		]
	}
	
	final override func viewDidLoad() {
		super.viewDidLoad()
		
		if Enabling.multialbum {
			navigationItem.largeTitleDisplayMode = .never
		}
	}
	
	final override func setUpBarButtons() {
		editingModeToolbarButtons = [
			sortButton, .flexibleSpace(),
			floatToTopButton, .flexibleSpace(),
			sinkToBottomButton,
		]
		
		super.setUpBarButtons()
		
		navigationItem.rightBarButtonItem = editButtonItem
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
	
	// MARK: - Library Items
	
	final override func shouldDismissAllViewControllersBeforeFreshenLibraryItems() -> Bool {
		if willPlayLaterAlertIsPresented {
			return false
		}
		
		return super.shouldDismissAllViewControllersBeforeFreshenLibraryItems()
	}
	
	final override func reflectViewModelIsEmpty() {
		deleteThenExit(sections: tableView.allSections())
	}
}
