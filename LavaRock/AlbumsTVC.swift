//
//  AlbumsTVC.swift
//  LavaRock
//
//  Created by h on 2020-04-28.
//  Copyright © 2020 h. All rights reserved.
//

import UIKit
import SwiftUI
import CoreData

final class AlbumsTVC: LibraryTVC {
	enum Purpose {
		case organizingAlbums(OrganizeAlbumsClipboard)
		case movingAlbums(MoveAlbumsClipboard)
		case browsing
	}
	
	// MARK: - Properties
	
	// Controls
	private lazy var moveButton = UIBarButtonItem(
		title: LRString.move,
		image: UIImage(systemName: "folder"),
		primaryAction: UIAction { [weak self] _ in self?.startMoving() }
	)
//	private lazy var moveButton = UIBarButtonItem(title: LRString.move)
	private lazy var arrangeAlbumsButton = UIBarButtonItem(
		title: LRString.sort,
		image: UIImage(systemName: "arrow.up.arrow.down")
	)
	
	// Purpose
	var purpose: Purpose {
		if let clipboard = organizeAlbumsClipboard { return .organizingAlbums(clipboard) }
		if let clipboard = moveAlbumsClipboard { return .movingAlbums(clipboard) }
		return .browsing
	}
	
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
			case .organizingAlbums(let clipboard):
				navigationItem.prompt = clipboard.prompt
			case .movingAlbums: break
			case .browsing:
				NotificationCenter.default.addObserverOnce(self, selector: #selector(didOrganizeAlbums), name: .LROrganizedAlbums, object: nil)
				NotificationCenter.default.addObserverOnce(self, selector: #selector(didMoveAlbums), name: .LRMovedAlbums, object: nil)
		}
		
		navigationItem.backButtonDisplayMode = .minimal
		tableView.separatorStyle = .none
	}
	
	override func setUpBarButtons() {
		switch purpose {
			case .organizingAlbums: break
			case .movingAlbums:
				viewingModeTopRightButtons = [
					{
						let moveHereButton = UIBarButtonItem(
							title: LRString.move,
							primaryAction: UIAction { [weak self] _ in self?.moveHere() }
						)
						moveHereButton.style = .done
						return moveHereButton
					}(),
				]
			case .browsing:
				editingModeToolbarButtons = [
					moveButton, .flexibleSpace(),
					arrangeAlbumsButton, .flexibleSpace(),
					floatButton, .flexibleSpace(),
					sinkButton, .flexibleSpace(),
					editButtonItem,
				]
		}
		super.setUpBarButtons()
	}
	
	@IBAction private func unwindToAlbums(_ unwindSegue: UIStoryboardSegue) {}
	
	override func viewWillTransition(
		to size: CGSize,
		with coordinator: UIViewControllerTransitionCoordinator
	) {
		super.viewWillTransition(to: size, with: coordinator)
		
		guard let albumsViewModel = viewModel as? AlbumsViewModel else { return }
		
		tableView.allIndexPaths().forEach { indexPath in // Don’t use `indexPathsForVisibleRows`, because that excludes cells that underlap navigation bars and toolbars.
			guard
				let cell = tableView.cellForRow(at: indexPath),
				albumsViewModel.pointsToSomeItem(row: indexPath.row)
			else { return }
			let album = albumsViewModel.albumNonNil(atRow: indexPath.row)
			let (mode, _) = new_albumCardMode_and_selectionStyle(album: album)
			cell.contentConfiguration = UIHostingConfiguration {
				AlbumCard(
					album: album,
					maxHeight: size.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom,
					mode: mode)
			}
			.margins(.all, .zero)
		}
	}
	
	// MARK: - Library items
	
	@objc
	private func didOrganizeAlbums() {
		let viewModel = viewModel.updatedWithFreshenedData() as! AlbumsViewModel // Shadowing so that we don’t accidentally refer to `self.viewModel`, which is incoherent at this point.
		Task {
			let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(viewModel)
		}
	}
	
	// Similar to `freshenLibraryItems`.
	// Call this from the modal `AlbumsTVC` in the “move albums” sheet after completing the animation for inserting the `Album`s we moved. This instance here, the base-level `AlbumsTVC`, should be the modal `AlbumsTVC`’s delegate, and this method removes the rows for those `Album`s.
	// That timing looks good: we remove the `Album`s while dismissing the sheet, so you catch just a glimpse of the `Album`s disappearing, even though it technically doesn’t make sense.
	@objc
	private func didMoveAlbums() {
		let newViewModel = viewModel.updatedWithFreshenedData()
		Task {
			let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel)
		}
	}
	
	override func freshenLibraryItems() {
		switch purpose {
			case .organizingAlbums, .movingAlbums: return
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
//		moveButton.menu = createMoveMenu()
		
		arrangeAlbumsButton.isEnabled = allowsArrange()
		arrangeAlbumsButton.menu = createArrangeMenu()
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
		
		let toCollection_element = UIAction(
			title: LRString.toCrateEllipsis,
			image: UIImage(systemName: "tray")
		) { [weak self] _ in
			self?.startMoving()
		}
		
		return UIMenu(children: [
			toCollection_element,
			byAlbumArtist_element,
		])
	}
	private static let arrangeCommands: [[ArrangeCommand]] = [
		[.album_newest, .album_oldest],
		[.random, .reverse],
	]
	private func createArrangeMenu() -> UIMenu {
		let elementsGrouped: [[UIMenuElement]] = Self.arrangeCommands.reversed().map {
			$0.reversed().map { command in
				command.createMenuElement(
					enabled: {
						guard unsortedRowsToArrange().count >= 2 else {
							return false
						}
						switch command {
							case .random, .reverse: return true
							case .collection_name, .song_track: return false
							case .album_newest, .album_oldest:
								let subjectedItems = unsortedRowsToArrange().map {
									viewModel.itemNonNil(atRow: $0)
								}
								guard let albums = subjectedItems as? [Album] else {
									return false
								}
								return albums.contains { $0.releaseDateEstimate != nil }
						}
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
