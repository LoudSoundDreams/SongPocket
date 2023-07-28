//
//  AlbumsTVC.swift
//  LavaRock
//
//  Created by h on 2020-04-28.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import CoreData
import SwiftUI

final class AlbumsTVC:
	LibraryTVC,
	OrganizeAlbumsPreviewing
{
	enum Purpose {
		case previewingCombine
		case organizingAlbums(OrganizeAlbumsClipboard)
		case movingAlbums(MoveAlbumsClipboard)
		case browsing
	}
	
	// MARK: - Properties
	
	private(set) lazy var noItemsBackgroundView: UIView? = {
		let view = Text(LRString.noAlbums)
			.foregroundStyle(.secondary)
			.font(.title)
		let hostingController = UIHostingController(rootView: view)
		return hostingController.view
	}()
	
	// Controls
	private var moveButton = UIBarButtonItem(
		title: LRString.move)
	
	// Purpose
	var purpose: Purpose {
		if is_previewing_combine_with_album_count != 0 {
			return .previewingCombine
		}
		if let clipboard = organizeAlbumsClipboard {
			return .organizingAlbums(clipboard)
		}
		if let clipboard = moveAlbumsClipboard {
			return .movingAlbums(clipboard)
		}
		return .browsing
	}
	
	// State
	var idsOfAlbumsToKeepSelected: Set<NSManagedObjectID> = []
	
	// MARK: “Combine folders” sheet
	
	var is_previewing_combine_with_album_count: Int = 0
	var cancel_combine_action: UIAction? = nil
	var save_combine_action: UIAction? = nil
	
	// MARK: “Organize albums” sheet
	
	// Data
	var organizeAlbumsClipboard: OrganizeAlbumsClipboard? = nil
	
	// Controls
	private lazy var saveOrganizeButton = makeSaveOrganizeButton()
	
	// MARK: “Move albums” sheet
	
	// Data
	var moveAlbumsClipboard: MoveAlbumsClipboard? = nil
	
	// MARK: - Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		sortCommandsGrouped = [
			[
				.album_released,
			],
			[
				.random,
				.reverse,
			],
		]
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		switch purpose {
			case .previewingCombine:
				navigationItem.prompt = String.localizedStringWithFormat(
					LRString.variable_moveXAlbumsIntoOneFolder_question_mark,
					is_previewing_combine_with_album_count)
			case .organizingAlbums(let clipboard):
				navigationItem.prompt = clipboard.prompt
			case .movingAlbums(let clipboard):
				navigationItem.prompt = clipboard.prompt
			case .browsing:
				break
		}
		
		navigationItem.largeTitleDisplayMode = .never
	}
	
	private lazy var save_combine_button: UIBarButtonItem = {
		let button = UIBarButtonItem(
			title: LRString.save,
			primaryAction: save_combine_action)
		button.style = .done
		return button
	}()
	override func setUpBarButtons() {
		switch purpose {
			case .previewingCombine:
				viewingModeTopRightButtons = [
					UIBarButtonItem(
						title: LRString.cancel,
						primaryAction: cancel_combine_action)
				].compacted()
				viewingModeToolbarButtons = [
					.flexibleSpace(),
					save_combine_button,
					.flexibleSpace(),
				].compacted()
			case .organizingAlbums:
				viewingModeTopRightButtons = [
					cancelAndDismissButton,
				]
				viewingModeToolbarButtons = [
					.flexibleSpace(),
					saveOrganizeButton,
					.flexibleSpace(),
				]
			case .movingAlbums:
				viewingModeTopRightButtons = [
					cancelAndDismissButton,
				]
			case .browsing:
				editingModeToolbarButtons = [
					moveButton,
					.flexibleSpace(),
					sortButton,
					.flexibleSpace(),
					floatToTopButton,
					.flexibleSpace(),
					sinkToBottomButton,
				]
		}
		
		super.setUpBarButtons()
		
		switch purpose {
			case .previewingCombine:
				showToolbar()
			case .organizingAlbums:
				break
			case .movingAlbums:
				break
			case .browsing:
				break
		}
		func showToolbar() {
			navigationController?.setToolbarHidden(false, animated: false)
		}
	}
	
	@IBAction private func unwindToAlbums(_ unwindSegue: UIStoryboardSegue) {
	}
	
	// MARK: - Library items
	
	override func freshenLibraryItems() {
		switch purpose {
			case .previewingCombine:
				return
			case .organizingAlbums:
				return
			case .movingAlbums:
				return
			case .browsing:
				super.freshenLibraryItems()
		}
	}
	
	override func reflectViewModelIsEmpty() {
		deleteThenExit(sectionsToDelete: tableView.allSections())
	}
	
	// MARK: - Freshening UI
	
	override func freshenEditingButtons() {
		super.freshenEditingButtons()
		
		moveButton.menu = makeMoveMenu()
		moveButton.isEnabled = allowsMove()
	}
	
	private func makeMoveMenu() -> UIMenu {
		let byAlbumArtist_element = UIDeferredMenuElement.uncached(
			{ [weak self] useMenuElements in
				// Runs each time the button presents the menu
				
				let menuElements: [UIMenuElement]
				defer {
					useMenuElements(menuElements)
				}
				
				guard let self else {
					menuElements = []
					return
				}
				
				let action = UIAction(
					title: LRString.byAlbumArtistEllipsis,
					image: UIImage(systemName: "music.mic")
				) { [weak self] _ in
					// Runs when the user activates the menu item
					self?.previewAutoMove()
				}
				
				// Disable if appropriate
				// This must be inside `UIDeferredMenuElement.uncached`. `UIMenu` caches `UIAction.attributes`.
				let allowed = (self.viewModel as? AlbumsViewModel)?.allowsAutoMove(
					selectedIndexPaths: self.tableView.selectedIndexPaths
				) ?? false
				if !allowed {
					action.attributes.formUnion(.disabled)
				}
				
				menuElements = [action]
			}
		)
		
		let toFolder_element = UIAction(
			title: LRString.toFolderEllipsis,
			image: UIImage(systemName: "folder")
		) { [weak self] _ in
			self?.startMoving()
		}
		
		return UIMenu(children: [
			toFolder_element,
			byAlbumArtist_element,
		])
	}
	
	private func allowsMove() -> Bool {
		guard !viewModel.isEmpty() else {
			return false
		}
		return true
	}
	
	// MARK: - Navigation
	
	override func prepare(
		for segue: UIStoryboardSegue,
		sender: Any?
	) {
		let albumsViewModel = viewModel as! AlbumsViewModel
		
		guard
			let selectedIndexPath = tableView.indexPathForSelectedRow,
			let songsTVC = segue.destination as? SongsTVC
		else { return }
		
		let album = albumsViewModel.albumNonNil(at: selectedIndexPath)
		songsTVC.viewModel = SongsViewModel(
			parentAlbum: .exists(album),
			context: viewModel.context)
	}
}
