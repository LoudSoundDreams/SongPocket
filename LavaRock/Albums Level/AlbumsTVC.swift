//
//  AlbumsTVC.swift
//  LavaRock
//
//  Created by h on 2020-04-28.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import CoreData
import MediaPlayer

final class AlbumsTVC:
	LibraryTVC,
	AlbumMover,
	NoItemsBackgroundManager
{
	
	enum SectionKind { // It'd be nice if raw values could be of type `Int?`.
		case all
		case groupOfAlbums
		
		static let valueForCaseAll = 0
		
		init(forSection section: Int) {
			if section == Self.valueForCaseAll {
				self = .all
			} else {
				self = .groupOfAlbums
			}
		}
	}
	
	// MARK: - Properties
	
	// Controls
	private lazy var moveOrOrganizeButton = UIBarButtonItem(
		title: LocalizedString.move,
		menu: moveOrOrganizeMenu())
	private lazy var moveButton: UIBarButtonItem = {
		let action = UIAction { _ in self.startMovingAlbums() }
		return UIBarButtonItem(
			title: LocalizedString.move,
			primaryAction: action)
	}()
	
	// NoItemsBackgroundManager
	lazy var noItemsBackgroundView = tableView.dequeueReusableCell(withIdentifier: "No Albums Placeholder")
	
	// MARK: "Moving Albums" Mode
	
	// Controls
	private lazy var moveHereButton: UIBarButtonItem = {
		let action = UIAction { _ in self.moveAlbumsHere() }
		let button = UIBarButtonItem(
			title: LocalizedString.moveHere,
			primaryAction: action)
		button.style = .done
		return button
	}()
	
	var albumMoverClipboard: AlbumMoverClipboard?
	
	// MARK: - Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		sortOptionsGrouped = [
			[.newestFirst, .oldestFirst],
			[.reverse],
		]
	}
	
	final override func setUpUI() {
		// Choose our buttons for the navigation bar and toolbar before calling super, because super sets those buttons.
		if albumMoverClipboard != nil {
			topRightButtons = [cancelMoveAlbumsButton]
			viewingModeToolbarButtons = [
				.flexibleSpace(),
				moveHereButton,
				.flexibleSpace(),
			]
		}
		
		super.setUpUI()
		
		if let albumMoverClipboard = albumMoverClipboard {
			navigationItem.prompt = albumMoverClipboard.navigationItemPrompt
			
			tableView.allowsSelection = false
			
			if FeatureFlag.tabBar {
				showToolbar()
			}
		} else {
			editingModeToolbarButtons = [
//				moveOrOrganizeButton, .flexibleSpace(),
				
				
				moveButton, .flexibleSpace(),
				sortButton, .flexibleSpace(),
				floatToTopButton, .flexibleSpace(),
				sinkToBottomButton,
			]
		}
	}
	
	// MARK: Setup Events
	
	@IBAction private func unwindToAlbumsFromEmptyAlbum(_ unwindSegue: UIStoryboardSegue) {
	}
	
	// MARK: - Refreshing UI
	
	final func reloadAllRow(with animation: UITableView.RowAnimation) {
		tableView.reloadSections([SectionKind.valueForCaseAll], with: animation)
	}
	
	final override func reflectViewModelIsEmpty() {
		if FeatureFlag.allRow {
			let toDelete = tableView.allSections().filter { $0 != SectionKind.valueForCaseAll }
			deleteThenExit(sections: toDelete)
			reloadAllRow(with: .none)
		} else {
			let toDelete = tableView.allSections()
			deleteThenExit(sections: toDelete)
		}
	}
	
	final override func refreshEditingButtons() {
		super.refreshEditingButtons()
		
		moveOrOrganizeButton.isEnabled = allowsMoveOrOrganize()
		moveButton.isEnabled = allowsMove()
	}
	
	private func allowsMoveOrOrganize() -> Bool {
		guard !viewModel.isEmpty() else {
			return false
		}
		if tableView.indexPathsForSelectedRowsNonNil.isEmpty {
			return viewModel.isSpecificallyOpenedContainer
		} else {
			return true
		}
	}
	
	private func allowsMove() -> Bool {
		return allowsMoveOrOrganize()
	}
	
	// MARK: - Navigation
	
	final override func prepare(
		for segue: UIStoryboardSegue,
		sender: Any?
	) {
		guard
			let selectedIndexPath = tableView.indexPathForSelectedRow,
			let songsTVC = segue.destination as? SongsTVC,
			let albumsViewModel = viewModel as? AlbumsViewModel
		else { return }
		
		let selectedCell = tableView.cellForRow(at: selectedIndexPath)
		if selectedCell is TheseContainersCell {
			songsTVC.viewModel = SongsViewModel(
				lastSpecificContainer: viewModel.lastSpecificContainer,
				context: viewModel.context)
		} else if selectedCell is AlbumCell {
			let album = albumsViewModel.item(at: selectedIndexPath)
			songsTVC.viewModel = SongsViewModel(
				lastSpecificContainer: album as? Album,
				context: viewModel.context)
		}
	}
	
}
