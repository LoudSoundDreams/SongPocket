// 2020-04-28

import UIKit
import SwiftUI
import MusicKit

final class AlbumsTVC: LibraryTVC {
	private var expandableViewModel = ExpandableViewModel()
	var albumsViewModel = AlbumsViewModel()
	private lazy var arrangeAlbumsButton = UIBarButtonItem(title: InterfaceText.sort, image: UIImage(systemName: "arrow.up.arrow.down"))
	private lazy var floatAlbumsButton = UIBarButtonItem(title: InterfaceText.moveToTop, image: UIImage(systemName: "arrow.up.to.line"), primaryAction: UIAction { [weak self] _ in self?.floatSelected() })
	private lazy var sinkAlbumsButton = UIBarButtonItem(title: InterfaceText.moveToBottom, image: UIImage(systemName: "arrow.down.to.line"), primaryAction: UIAction { [weak self] _ in self?.sinkSelected() })
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		editingButtons = [editButtonItem, .flexibleSpace(), arrangeAlbumsButton, .flexibleSpace(), floatAlbumsButton, .flexibleSpace(), sinkAlbumsButton]
		
		super.viewDidLoad()
		
		navigationItem.backButtonDisplayMode = .minimal
		tableView.separatorStyle = .none
		
		NotificationCenter.default.addObserverOnce(self, selector: #selector(showAlbumDetail), name: .LRShowAlbumDetail, object: nil)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(hideAlbumDetail), name: .LRHideAlbumDetail, object: nil)
		__MainToolbar.shared.albumsTVC = WeakRef(self)
	}
	@objc private func showAlbumDetail(notification: Notification) {
		guard let album = notification.object as? Album else { return }
		expandableViewModel.collapseAllThenExpand(album)
	}
	@objc private func hideAlbumDetail(notification: Notification) {
		expandableViewModel.collapseAll()
	}
	
	override func viewWillTransition(
		to size: CGSize,
		with coordinator: UIViewControllerTransitionCoordinator
	) {
		super.viewWillTransition(to: size, with: coordinator)
		
		tableView.allIndexPaths().forEach { indexPath in // Don’t use `indexPathsForVisibleRows`, because that excludes cells that underlap navigation bars and toolbars.
			guard let cell = tableView.cellForRow(at: indexPath) else { return }
			let album = albumsViewModel.albums[indexPath.row]
			cell.contentConfiguration = UIHostingConfiguration {
				AlbumRow(
					album: album,
					maxHeight: size.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom)
			}.margins(.all, .zero)
		}
	}
	
	func showCurrentAlbum() {
		guard let currentAlbum = albumsViewModel.albums.first(where: { album in
			album.songs(sorted: false).contains { $0.isInPlayer() }
		}) else { return }
		navigationController?.popToRootViewController(animated: true)
		let indexPath = IndexPath(row: Int(currentAlbum.index), section: 0)
		// TO DO: Wait until this view appears before scrolling.
		tableView.scrollToRow(at: indexPath, at: .top, animated: true)
	}
	
	// MARK: - Editing
	
	override func refreshEditingButtons() {
		super.refreshEditingButtons()
		arrangeAlbumsButton.isEnabled = allowsArrange()
		arrangeAlbumsButton.menu = createArrangeMenu()
		floatAlbumsButton.isEnabled = allowsFloatAndSink()
		sinkAlbumsButton.isEnabled = allowsFloatAndSink()
	}
	private func createArrangeMenu() -> UIMenu {
		let sections: [[ArrangeCommand]] = [
			[.album_recentlyAdded, .album_newest, .album_artist],
			[.random, .reverse],
		]
		let elementsGrouped: [[UIMenuElement]] = sections.reversed().map { section in
			section.reversed().map { command in
				command.createMenuElement(enabled: {
					guard selectedOrAllIndices().count >= 2 else { return false }
					switch command {
						case .random, .reverse: return true
						case .song_track: return false
						case .album_recentlyAdded, .album_artist: return true
						case .album_newest:
							let toSort = selectedOrAllIndices().map { albumsViewModel.albums[$0] }
							return toSort.contains { $0.releaseDateEstimate != nil }
					}
				}()) { [weak self] in self?.arrangeSelectedOrAll(by: command) }
			}
		}
		let inlineSubmenus = elementsGrouped.map {
			UIMenu(options: .displayInline, children: $0)
		}
		return UIMenu(children: inlineSubmenus)
	}
	private func arrangeSelectedOrAll(by command: ArrangeCommand) {
		var newViewModel = albumsViewModel
		newViewModel.albums = {
			let subjectedIndicesInOrder = selectedOrAllIndices().sorted()
			let toSort = subjectedIndicesInOrder.map { albumsViewModel.albums[$0] }
			let sorted = command.apply(to: toSort) as! [Album]
			var result = albumsViewModel.albums
			subjectedIndicesInOrder.indices.forEach { counter in
				let replaceAt = subjectedIndicesInOrder[counter]
				let newItem = sorted[counter]
				result[replaceAt] = newItem
			}
			return result
		}()
		Task { let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel) }
	}
	private func selectedOrAllIndices() -> [Int] {
		let selected = tableView.selectedIndexPaths
		guard !selected.isEmpty else { return albumsViewModel.albums.indices.map { $0 } }
		return selected.map { $0.row }
	}
	private func allowsFloatAndSink() -> Bool {
		guard !albumsViewModel.albums.isEmpty else { return false }
		return !tableView.selectedIndexPaths.isEmpty
	}
	private func floatSelected() {
		var allAlbums = albumsViewModel.albums
		let unorderedIndices = tableView.selectedIndexPaths.map { $0.row }
		allAlbums.move(fromOffsets: IndexSet(unorderedIndices), toOffset: 0)
		Database.renumber(allAlbums)
		// Don’t use `refreshLibraryItems`, because that deselects rows without an animation if no rows moved.
		let newViewModel = albumsViewModel.withRefreshedData()
		Task { let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel) }
	}
	private func sinkSelected() {
		var allAlbums = albumsViewModel.albums
		let unorderedIndices = tableView.selectedIndexPaths.map { $0.row }
		allAlbums.move(fromOffsets: IndexSet(unorderedIndices), toOffset: allAlbums.count)
		Database.renumber(allAlbums)
		let newViewModel = albumsViewModel.withRefreshedData()
		Task { let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel) }
	}
	
	// MARK: - Table view
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		refreshPlaceholder()
		return 1
	}
	private func refreshPlaceholder() {
		contentUnavailableConfiguration = {
			guard MusicAuthorization.currentStatus == .authorized else {
				return UIHostingConfiguration {
					ContentUnavailableView {
					} description: {
						Text(InterfaceText.welcome_message)
					} actions: {
						Button(InterfaceText.welcome_button) {
							Task { await AppleMusic.requestAccess() }
						}
					}
				}.margins(.all, .zero) // As of iOS 17.5 developer beta 1, this prevents the content from sometimes jumping vertically.
			}
			if albumsViewModel.albums.isEmpty {
				return UIHostingConfiguration {
					ContentUnavailableView {
					} actions: {
						Button(InterfaceText.emptyLibrary_button) {
							let musicURL = URL(string: "music://")!
							UIApplication.shared.open(musicURL)
						}
					}
				}
			}
			return nil
		}()
	}
	override func tableView(
		_ tableView: UITableView, numberOfRowsInSection section: Int
	) -> Int {
		guard MusicAuthorization.currentStatus == .authorized else { return 0 }
		return albumsViewModel.albums.count
	}
	
	override func tableView(
		_ tableView: UITableView, cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		// The cell in the storyboard is completely default except for the reuse identifier.
		let cell = tableView.dequeueReusableCell(withIdentifier: "Album Card", for: indexPath)
		guard WorkingOn.inlineTracklist else {
			return configuredCellForAlbum(cell: cell, album: albumsViewModel.albums[indexPath.row])
		}
		switch expandableViewModel.itemForIndexPath(indexPath) {
			case .album(let album): return configuredCellForAlbum(cell: cell, album: album)
			case .song(let song): return Self.configuredCellForSong(cell: cell, song: song)
		}
	}
	private func configuredCellForAlbum(cell: UITableViewCell, album: Album) -> UITableViewCell {
		cell.backgroundColor = .clear
		cell.selectedBackgroundView = {
			let result = UIView()
			result.backgroundColor = .tintColor.withAlphaComponent(.oneHalf)
			return result
		}()
		cell.contentConfiguration = UIHostingConfiguration {
			AlbumRow(album: album, maxHeight: {
				let height = view.frame.height
				let topInset = view.safeAreaInsets.top
				let bottomInset = view.safeAreaInsets.bottom
				return height - topInset - bottomInset
			}())
		}.margins(.all, .zero)
		return cell
	}
	private static func configuredCellForSong(cell: UITableViewCell, song: Song) -> UITableViewCell {
		cell.contentConfiguration = UIHostingConfiguration {
			Text(song.songInfo()?.titleOnDisk ?? InterfaceText.emDash)
		}
		return cell
	}
	
	override func tableView(
		_ tableView: UITableView, didSelectRowAt indexPath: IndexPath
	) {
		if !WorkingOn.inlineTracklist {
			if !isEditing {
				pushAlbum(albumsViewModel.albums[indexPath.row])
			}
		}
		super.tableView(tableView, didSelectRowAt: indexPath)
	}
	private func pushAlbum(_ album: Album) {
		navigationController?.pushViewController({
			let songsTVC = UIStoryboard(name: "SongsTVC", bundle: nil).instantiateInitialViewController() as! SongsTVC
			songsTVC.songsViewModel = SongsViewModel(album: album)
			return songsTVC
		}(), animated: true)
	}
	
	override func tableView(
		_ tableView: UITableView,
		moveRowAt source: IndexPath,
		to destination: IndexPath
	) {
		let fromIndex = source.row
		let toIndex = destination.row
		
		var newItems = albumsViewModel.albums
		let passenger = newItems.remove(at: fromIndex)
		newItems.insert(passenger, at: toIndex)
		albumsViewModel.albums = newItems
		
		refreshEditingButtons() // If you made selected rows non-contiguous, that should disable the “Sort” button. If you made all the selected rows contiguous, that should enable the “Sort” button.
	}
}
