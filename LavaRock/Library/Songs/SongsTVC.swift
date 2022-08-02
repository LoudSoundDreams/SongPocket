//
//  SongsTVC.swift
//  LavaRock
//
//  Created by h on 2020-05-04.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import MediaPlayer

final class SongsTVC:
	LibraryTVC,
	NoItemsBackgroundManager
{
	// MARK: - Properties
	
	// `NoItemsBackgroundManager`
	lazy var noItemsBackgroundView = tableView.dequeueReusableCell(withIdentifier: "No Songs Placeholder")
	
	// State
	var openedAlbum: Album? = nil
	
	// MARK: - Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		sortOptionsGrouped = [
			[.trackNumber],
			[.shuffle, .reverse],
		]
	}
	
	override func setUpBarButtons() {
		editingModeToolbarButtons = [
			sortButton,
			.flexibleSpace(),
			floatToTopButton,
			.flexibleSpace(),
			sinkToBottomButton,
		]
		
		super.setUpBarButtons()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if let album = openedAlbum {
			openedAlbum = nil
			if let indexPath = (viewModel as? SongsViewModel)?.indexPath(for: album) {
				tableView.scrollToRow(at: indexPath, at: .top, animated: false)
			}
		}
	}
	
	// MARK: - Library Items
	
	override func reflectViewModelIsEmpty() {
		deleteThenExit(sectionsToDelete: tableView.allSections())
	}
	
	func mediaItems(
		startingAt firstIndexPath: IndexPath
	) -> [MPMediaItem] {
		return viewModel
			.itemsInGroup(startingAt: firstIndexPath)
			.compactMap { ($0 as? Song)?.mpMediaItem() }
	}
	
	// Time complexity: O(n), where “n” is the number of media items in the group.
	func mediaItemsInFirstGroup(
		startingAt firstMediaItem: MPMediaItem
	) -> [MPMediaItem] {
		let allMediaItems = mediaItems(
			startingAt: viewModel.indexPathFor(
				itemIndex: 0,
				groupIndex: 0
			)
		)
		let result = allMediaItems.drop { mediaItem in
			mediaItem.persistentID != firstMediaItem.persistentID
		}
		return Array(result)
	}
}
