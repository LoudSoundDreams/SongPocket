//
//  SongsTVC.swift
//  LavaRock
//
//  Created by h on 2020-05-04.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import MediaPlayer
import SwiftUI

final class SongsTVC: LibraryTVC {
	// MARK: - Properties
	
	private(set) lazy var noItemsBackgroundView: UIView? = {
		let view = Text(LRString.noSongs)
			.foregroundStyle(.secondary)
			.font(.title)
		let hostingController = UIHostingController(rootView: view)
		return hostingController.view
	}()
	
	// MARK: - Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		sortCommandsGrouped = [
			[.song_track, .song_added],
			[.random, .reverse],
		]
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		title = nil
	}
	
	override func reflectViewContainer() {
		// Freshen each `Album` whose info we’re showing.
		// Currently, we always reload all table view cells after this method, which takes care of that for us.
	}
	
	override func setUpBarButtons() {
		editingModeToolbarButtons = [
			sortButton,
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
		super.viewWillTransition(
			to: size,
			with: coordinator)
		
		if
			let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)), // !
			let coverArtCell = cell as? CoverArtCell
		{
			coverArtCell.configureArtwork(maxHeight: size.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom)
		}
	}
	
	// MARK: - Library items
	
	override func reflectViewModelIsEmpty() {
		deleteThenExit(sectionsToDelete: tableView.allSections())
	}
	
	func mediaItems(startingAtRow: Int) -> [MPMediaItem] {
		return viewModel
			.items(startingAtRow: startingAtRow)
			.compactMap { ($0 as? Song)?.mpMediaItem() }
	}
}
