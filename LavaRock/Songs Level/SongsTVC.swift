//
//  SongsTVC.swift
//  LavaRock
//
//  Created by h on 2020-05-04.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import MediaPlayer

final class SongsTVC: LibraryTVC {
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		arrangeFoldersOrSongsCommands = [
			[.song_track, .song_added],
			[.random, .reverse],
		]
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		title = nil
	}
	
	override func setUpBarButtons() {
		editingModeToolbarButtons = [
			arrangeFoldersOrSongsButton,
			.flexibleSpace(),
			floatButton,
			.flexibleSpace(),
			sinkButton,
		]
		
		super.setUpBarButtons()
	}
	
	override func viewWillTransition(
		to size: CGSize,
		with coordinator: UIViewControllerTransitionCoordinator
	) {
		super.viewWillTransition(to: size, with: coordinator)
		
		if
			let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)), // !
			let coverArtCell = cell as? CoverArtCell
		{
			coverArtCell.configureArtwork(maxHeight: size.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom)
		}
	}
	
	override func reflectViewModelIsEmpty() {
		deleteThenExit(sectionsToDelete: tableView.allSections())
	}
	
	func mediaItems() -> [MPMediaItem] {
		let items = Array(viewModel.libraryGroup().items)
		return items.compactMap { ($0 as? Song)?.mpMediaItem() }
	}
}
