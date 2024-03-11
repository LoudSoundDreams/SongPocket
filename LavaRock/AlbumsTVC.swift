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
			let (mode, _) = new_albumRowMode_and_selectionStyle(album: album)
			cell.contentConfiguration = UIHostingConfiguration {
				AlbumRow(
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
	
	// MARK: - Table view
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		if viewModel.isEmpty() {
			contentUnavailableConfiguration = UIHostingConfiguration {
				Image(systemName: "square.stack")
					.foregroundStyle(.secondary)
					.font(.title)
			}
			.margins(.all, .zero)
		} else {
			contentUnavailableConfiguration = nil
		}
		
		return viewModel.groups.count
	}
	
	override func tableView(
		_ tableView: UITableView, numberOfRowsInSection section: Int
	) -> Int {
		let albumsViewModel = viewModel as! AlbumsViewModel
		if albumsViewModel.collection == nil {
			return 0
		} else {
			return albumsViewModel.libraryGroup().items.count
		}
	}
	
	override func tableView(
		_ tableView: UITableView, cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		// The cell in the storyboard is completely default except for the reuse identifier and selection segue.
		let cell = tableView.dequeueReusableCell(withIdentifier: "Album Card", for: indexPath)
		let album = (viewModel as! AlbumsViewModel).albumNonNil(atRow: indexPath.row)
		let (mode, enabled) = new_albumRowMode_and_selectionStyle(album: album)
		cell.backgroundColors_configureForLibraryItem()
		cell.isUserInteractionEnabled = enabled
		if enabled {
			cell.accessibilityTraits.subtract(.notEnabled)
		} else {
			cell.accessibilityTraits.formUnion(.notEnabled)
		}
		cell.contentConfiguration = UIHostingConfiguration {
			AlbumRow(
				album: album,
				maxHeight: {
					let height = view.frame.height
					let topInset = view.safeAreaInsets.top
					let bottomInset = view.safeAreaInsets.bottom
					return height - topInset - bottomInset
				}(),
				mode: mode)
		}
		.margins(.all, .zero)
		return cell
	}
	func new_albumRowMode_and_selectionStyle(album: Album) -> (
		mode: AlbumRow.Mode,
		enabled: Bool
	) {
		let mode: AlbumRow.Mode = {
			switch purpose {
				case .movingAlbums(let clipboard):
					if clipboard.idsOfAlbumsBeingMovedAsSet.contains(album.objectID) {
						return .disabledTinted
					}
					return .disabled
				case .browsing:
					return .normal
			}
		}()
		let enabled: Bool = {
			switch purpose {
				case .movingAlbums: return false
				case .browsing: return true
			}
		}()
		return (mode, enabled)
	}
}
