//
//  AlbumsTVC.swift
//  LavaRock
//
//  Created by h on 2020-04-28.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import CoreData

final class AlbumsTVC:
	LibraryTVC,
	NoItemsBackgroundManager,
	OrganizeAlbumsPreviewing
{
	enum Purpose {
		case organizingAlbums(OrganizeAlbumsClipboard)
		case movingAlbums(MoveAlbumsClipboard)
		case browsing
	}
	
	// MARK: - Properties
	
	// `NoItemsBackgroundManager`
	private(set) lazy var noItemsBackgroundView = tableView.dequeueReusableCell(withIdentifier: "No Albums Placeholder")
	
	// Controls
	private var moveOrOrganizeButton = UIBarButtonItem(
		title: LRString.move)
	
	// Purpose
	var purpose: Purpose {
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
	
	// MARK: “Organize Albums” Sheet
	
	// Data
	var organizeAlbumsClipboard: OrganizeAlbumsClipboard? = nil
	
	// Controls
	private lazy var saveOrganizeButton = makeSaveOrganizeButton()
	
	// MARK: “Move Albums” Sheet
	
	// Data
	var moveAlbumsClipboard: MoveAlbumsClipboard? = nil
	
	// MARK: - Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		sortOptionsGrouped = [
			[.newestFirst, .oldestFirst],
			[.shuffle, .reverse],
		]
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		switch purpose {
		case .organizingAlbums(let clipboard):
			navigationItem.prompt = clipboard.prompt
		case .movingAlbums(let clipboard):
			navigationItem.prompt = clipboard.prompt
		case .browsing:
			break
		}
	}
	
	override func setUpBarButtons() {
		switch purpose {
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
				moveOrOrganizeButton,
				.flexibleSpace(),
				sortButton,
				.flexibleSpace(),
				floatToTopButton,
				.flexibleSpace(),
				sinkToBottomButton,
			]
		}
		
		super.setUpBarButtons()
	}
	
	@IBAction private func unwindToAlbumsFromEmptyAlbum(_ unwindSegue: UIStoryboardSegue) {
	}
	
	// MARK: - Library Items
	
	override func freshenLibraryItems() {
		switch purpose {
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
		
		moveOrOrganizeButton.menu = makeOrganizeOrMoveMenu()
		moveOrOrganizeButton.isEnabled = allowsMoveOrOrganize()
	}
	
	private func makeOrganizeOrMoveMenu() -> UIMenu {
		let organizeElement = UIDeferredMenuElement.uncached({ [weak self] useMenuElements in
			// Runs each time the button presents the menu
			let menuElements: [UIMenuElement]
			defer {
				useMenuElements(menuElements)
			}
			
			let organizeAction = UIAction(
				title: LRString.organizeByAlbumArtistEllipsis,
				image: UIImage(systemName: "folder.badge.gearshape")
			) { [weak self] _ in
				// Runs when the user activates the menu item
				self?.startOrganizing()
			}
			
			guard let self = self else {
				menuElements = []
				return
			}
			
			let allowed = (self.viewModel as? AlbumsViewModel)?.allowsOrganize(
				selectedIndexPaths: self.tableView.selectedIndexPaths) ?? false
			// Disable if appropriate
			// This must be inside `UIDeferredMenuElement.uncached`. `UIMenu` caches `UIAction.attributes`.
			organizeAction.attributes = (
				allowed
				? []
				: .disabled
			)
			
			menuElements = [organizeAction]
		})
		
		let moveElement = UIAction(
			title: LRString.moveToEllipsis,
			image: UIImage(systemName: "folder")
		) { [weak self] _ in
			self?.startMoving()
		}
		
		return UIMenu(
			title: {
				let subjectedCount = viewModel.unsortedOrForAllItemsIfNoneSelectedAndViewContainerIsSpecific(
					selectedIndexPaths: tableView.selectedIndexPaths)
					.count
				return String.localizedStringWithFormat(
					LRString.format_xAlbums,
					subjectedCount)
			}(),
			children: [
				organizeElement,
				moveElement,
			].reversed()
		)
	}
	
	private func allowsMoveOrOrganize() -> Bool {
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
