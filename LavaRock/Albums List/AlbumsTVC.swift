//
//  AlbumsTVC.swift
//  LavaRock
//
//  Created by h on 2020-04-28.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import CoreData

final class AlbumsTVC: LibraryTVC, OrganizeAlbumsPreviewing {
	enum Purpose {
		case previewingCombine
		case organizingAlbums(OrganizeAlbumsClipboard)
		case movingAlbums(MoveAlbumsClipboard)
		case browsing
	}
	
	// MARK: - Properties
	
	// Controls
	private lazy var arrangeAlbumsButton = UIBarButtonItem(title: LRString.arrange)
	private lazy var moveButton = UIBarButtonItem(title: LRString.move)
	
	// Purpose
	var purpose: Purpose {
		if is_previewing_combine_with_album_count != 0 { return .previewingCombine }
		if let clipboard = organizeAlbumsClipboard { return .organizingAlbums(clipboard) }
		if let clipboard = moveAlbumsClipboard { return .movingAlbums(clipboard) }
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
	
	// MARK: “Move albums” sheet
	
	// Data
	var moveAlbumsClipboard: MoveAlbumsClipboard? = nil
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		switch purpose {
			case .previewingCombine:
				navigationItem.prompt = String.localizedStringWithFormat(
					LRString.variable_createStackFromXAlbums_questionMark,
					is_previewing_combine_with_album_count)
			case .organizingAlbums(let clipboard):
				navigationItem.prompt = clipboard.prompt
			case .movingAlbums(let clipboard):
				navigationItem.prompt = clipboard.prompt
			case .browsing: break
		}
		
		navigationItem.backButtonDisplayMode = .minimal
		title = { () -> String in
			return (viewModel as! AlbumsViewModel).folder?.title ?? ""
		}()
		tableView.separatorStyle = .none
	}
	
	override func setUpBarButtons() {
		switch purpose {
			case .previewingCombine:
				viewingModeTopLeftButtons = [
					UIBarButtonItem(systemItem: .cancel, primaryAction: cancel_combine_action),
				]
				viewingModeTopRightButtons = [
					{
						let saveCombineButton = UIBarButtonItem(systemItem: .save, primaryAction: save_combine_action)
						saveCombineButton.style = .done
						return saveCombineButton
					}(),
				]
			case .organizingAlbums:
				break
			case .movingAlbums:
				viewingModeTopRightButtons = [
					{
						let moveButton = UIBarButtonItem(title: LRString.move, primaryAction: UIAction { [weak self] _ in
							self?.moveHere()
						})
						moveButton.style = .done
						return moveButton
					}(),
				]
			case .browsing:
				viewingModeTopRightButtons = [editButtonItem]
				editingModeToolbarButtons = [
					moveButton, .flexibleSpace(),
					arrangeAlbumsButton, .flexibleSpace(),
					floatButton, .flexibleSpace(),
					sinkButton,
				]
		}
		
		super.setUpBarButtons()
	}
	
	@IBAction private func unwindToAlbums(_ unwindSegue: UIStoryboardSegue) {}
	
	// MARK: - Library items
	
	override func freshenLibraryItems() {
		switch purpose {
			case .previewingCombine, .organizingAlbums, .movingAlbums: return
			case .browsing: super.freshenLibraryItems()
		}
	}
	
	override func reflectViewModelIsEmpty() {
		deleteThenExit(sectionsToDelete: tableView.allSections())
	}
	
	// MARK: - Freshening UI
	
	override func freshenEditingButtons() {
		super.freshenEditingButtons()
		
		moveButton.isEnabled = {
			guard !viewModel.isEmpty() else {
				return false
			}
			return true
		}()
		moveButton.menu = createMoveMenu()
		
		arrangeAlbumsButton.isEnabled = allowsArrange()
		arrangeAlbumsButton.menu = createArrangeAlbumsMenu()
	}
	private func createMoveMenu() -> UIMenu {
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
					title: LRString.byArtistEllipsis,
					image: UIImage(systemName: "music.mic")
				) { [weak self] _ in
					// Runs when the user activates the menu item
					self?.previewAutoMove()
				}
				
				// Disable if appropriate
				// This must be inside `UIDeferredMenuElement.uncached`. `UIMenu` caches `UIAction.attributes`.
				let allowed = (self.viewModel as! AlbumsViewModel).allowsAutoMove(
					selectedIndexPaths: self.tableView.selectedIndexPaths)
				if !allowed {
					action.attributes.formUnion(.disabled)
				}
				
				menuElements = [action]
			}
		)
		
		let toFolder_element = UIAction(
			title: LRString.toFolderEllipsis,
			image: UIImage(systemName: "square.stack")
		) { [weak self] _ in
			self?.startMoving()
		}
		
		return UIMenu(children: [
			toFolder_element,
			byAlbumArtist_element,
		])
	}
	private static let arrangeCommands: [[ArrangeCommand]] = [
		[.album_released],
		[.random, .reverse],
	]
	private func createArrangeAlbumsMenu() -> UIMenu {
		let setOfCommands: Set<ArrangeCommand> = Set(Self.arrangeCommands.flatMap { $0 })
		let elementsGrouped: [[UIMenuElement]] = Self.arrangeCommands.reversed().map {
			$0.reversed().map { command in
				command.createMenuElement(
					enabled: {
						guard
							unsortedRowsToArrange().count >= 2,
							setOfCommands.contains(command)
						else {
							return false
						}
						
						guard command != .album_released else {
							let subjectedItems = unsortedRowsToArrange().map {
								viewModel.itemNonNil(atRow: $0)
							}
							guard let albums = subjectedItems as? [Album] else {
								return false
							}
							return albums.contains { $0.releaseDateEstimate != nil }
						}
						return true
					}()
				) { [weak self] in
					self?.arrangeSelectedOrAll(by: command)
				}
			}
		}
		let inlineSubmenus = elementsGrouped.map {
			UIMenu(options: .displayInline, children: $0)
		}
		return UIMenu(children: inlineSubmenus)
	}
	
	// MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		let albumsViewModel = viewModel as! AlbumsViewModel
		
		guard
			let selectedIndexPath = tableView.indexPathForSelectedRow,
			let songsTVC = segue.destination as? SongsTVC
		else { return }
		
		let selectedAlbum = albumsViewModel.albumNonNil(atRow: selectedIndexPath.row)
		songsTVC.viewModel = SongsViewModel(
			album: selectedAlbum,
			context: viewModel.context)
	}
}
