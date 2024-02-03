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
	private lazy var arrangeAlbumsButton = UIBarButtonItem(
		title: LRString.sort,
		image: UIImage(systemName: "arrow.up.arrow.down")
	)
	
	// Purpose
	var purpose: Purpose {
		if let clipboard = moveAlbumsClipboard { return .movingAlbums(clipboard) }
		return .browsing
	}
	
	// MARK: “Move albums” sheet
	
	// Data
	var moveAlbumsClipboard: MoveAlbumsClipboard? = nil
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		switch purpose {
			case .movingAlbums: break
			case .browsing:
				editingButtons = [
					editButtonItem, .flexibleSpace(),
					moveButton, .flexibleSpace(),
					arrangeAlbumsButton, .flexibleSpace(),
					floatButton, .flexibleSpace(),
					sinkButton,
				]
		}
		
		super.viewDidLoad()
		
		switch purpose {
			case .movingAlbums: break
			case .browsing:
				NotificationCenter.default.addObserverOnce(self, selector: #selector(reflectDatabase), name: .LRUserUpdatedDatabase, object: nil)
		}
		
		navigationItem.backButtonDisplayMode = .minimal
		tableView.separatorStyle = .none
		
		switch purpose {
			case .movingAlbums:
				navigationItem.setRightBarButton(
					{
						let moveHereButton = UIBarButtonItem(
							title: LRString.move,
							primaryAction: UIAction { [weak self] _ in self?.moveHere() }
						)
						moveHereButton.style = .done
						return moveHereButton
					}(),
					animated: false)
			case .browsing: break
		}
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
	
	override func freshenLibraryItems() {
		switch purpose {
			case .movingAlbums: return
			case .browsing: super.freshenLibraryItems()
		}
	}
	
	override func reflectViewModelIsEmpty() {
		deleteThenExit(sectionsToDelete: tableView.allSections())
	}
	
	// MARK: Editing
	
	private func startMoving() {
		// Prepare a Collections view to present modally.
		let nc = UINavigationController(
			rootViewController: UIStoryboard(name: "CollectionsTVC", bundle: nil)
				.instantiateInitialViewController()!
		)
		guard
			let collectionsTVC = nc.viewControllers.first as? CollectionsTVC,
			let selfVM = viewModel as? AlbumsViewModel
		else { return }
		
		// Configure the `CollectionsTVC`.
		collectionsTVC.moveAlbumsClipboard = MoveAlbumsClipboard(albumsBeingMoved: {
			var subjectedRows: [Int] = tableView.selectedIndexPaths.map { $0.row }
			subjectedRows.sort()
			if subjectedRows.isEmpty {
				subjectedRows = selfVM.rowsForAllItems()
			}
			return subjectedRows.map {
				selfVM.albumNonNil(atRow: $0)
			}
		}())
		collectionsTVC.viewModel = CollectionsViewModel(context: {
			let childContext = NSManagedObjectContext(.mainQueue)
			childContext.parent = viewModel.context
			return childContext
		}())
		
		present(nc, animated: true)
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
		
		arrangeAlbumsButton.isEnabled = allowsArrange()
		arrangeAlbumsButton.menu = createArrangeMenu()
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
