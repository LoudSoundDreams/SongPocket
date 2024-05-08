// 2020-04-28

import UIKit
import SwiftUI
import MusicKit

final class AlbumsTVC: LibraryTVC {
	private var expandableViewModel = ExpandableViewModel()
	private lazy var arrangeAlbumsButton = UIBarButtonItem(title: LRString.sort, image: UIImage(systemName: "arrow.up.arrow.down"))
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		editingButtons = [editButtonItem, .flexibleSpace(), arrangeAlbumsButton, .flexibleSpace(), floatButton, .flexibleSpace(), sinkButton]
		
		super.viewDidLoad()
		
		navigationItem.backButtonDisplayMode = .minimal
		tableView.separatorStyle = .none
		
		NotificationCenter.default.addObserverOnce(self, selector: #selector(showAlbumDetail), name: .LRShowAlbumDetail, object: nil)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(hideAlbumDetail), name: .LRHideAlbumDetail, object: nil)
		__MainToolbar.shared.albumsTVC = Weak(self)
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
			let album = viewModel.items[indexPath.row] as! Album
			cell.contentConfiguration = UIHostingConfiguration {
				AlbumRow(
					album: album,
					maxHeight: size.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom)
			}.margins(.all, .zero)
		}
	}
	
	var isBeneathCurrentAlbum: Bool {
		guard let pushedAlbum = (((navigationController?.topViewController as? SongsTVC)?.viewModel as? SongsViewModel)?.items.first as? Song)?.container else { return false }
		return pushedAlbum.songs(sorted: false).contains { $0.isInPlayer() }
	}
	func goToCurrentAlbum() {
		guard !WorkingOn.inlineTracklist else {
			expandCurrentAlbum()
			return
		}
		guard
			!isBeneathCurrentAlbum,
			let albumToOpen = (viewModel.items as! [Album]).first(where: { album in
				album.songs(sorted: false).contains { $0.isInPlayer() }
			})
		else { return }
		navigationController?.popToRootViewController(animated: true)
		let indexPath = IndexPath(row: Int(albumToOpen.index), section: 0)
		tableView.performBatchUpdates {
			tableView.scrollToRow(at: indexPath, at: .top, animated: true)
		} completion: { _ in
			self.tableView.performBatchUpdates {
				self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
			} completion: { _ in
				self.pushAlbum(albumToOpen)
			}
		}
	}
	private func expandCurrentAlbum() {
		guard let albumToOpen = (viewModel.items as! [Album]).first(where: { album in
			album.songs(sorted: false).contains { $0.isInPlayer() }
		}) else { return }
		let indexPath = IndexPath(row: Int(albumToOpen.index), section: 0)
		tableView.scrollToRow(at: indexPath, at: .top, animated: true)
	}
	private func pushAlbum(_ album: Album) {
		navigationController?.pushViewController({
			let songsTVC = UIStoryboard(name: "SongsTVC", bundle: nil).instantiateInitialViewController() as! SongsTVC
			songsTVC.viewModel = SongsViewModel(album: album)
			return songsTVC
		}(), animated: true)
	}
	
	// MARK: - Editing
	
	override func refreshEditingButtons() {
		super.refreshEditingButtons()
		arrangeAlbumsButton.isEnabled = allowsArrange()
		arrangeAlbumsButton.menu = createArrangeMenu()
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
							let toSort = selectedOrAllIndices().map { viewModel.items[$0] } as! [Album]
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
						Text(LRString.welcome_message)
					} actions: {
						Button(LRString.welcome_button) {
							Task { await AppleMusic.requestAccess() }
						}
					}
				}.margins(.all, .zero) // As of iOS 17.5 developer beta 1, this prevents the content from sometimes jumping vertically.
			}
			if viewModel.items.isEmpty {
				return UIHostingConfiguration {
					ContentUnavailableView {
					} actions: {
						Button(LRString.emptyLibrary_button) {
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
		return viewModel.items.count
	}
	
	override func tableView(
		_ tableView: UITableView, cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		// The cell in the storyboard is completely default except for the reuse identifier.
		let cell = tableView.dequeueReusableCell(withIdentifier: "Album Card", for: indexPath)
		guard WorkingOn.inlineTracklist else {
			return configuredCellForAlbum(cell: cell, album: viewModel.items[indexPath.row] as! Album)
		}
		switch expandableViewModel.itemForIndexPath(indexPath) {
			case .album(let album): return configuredCellForAlbum(cell: cell, album: album)
			case .song(let song): return Self.configuredCellForSong(cell: cell, song: song)
		}
	}
	private func configuredCellForAlbum(cell: UITableViewCell, album: Album) -> UITableViewCell {
		cell.backgroundColors_configureForLibraryItem()
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
			Text(song.songInfo()?.titleOnDisk ?? LRString.emDash)
		}
		return cell
	}
	
	override func tableView(
		_ tableView: UITableView, didSelectRowAt indexPath: IndexPath
	) {
		if !WorkingOn.inlineTracklist {
			if !isEditing {
				pushAlbum(viewModel.items[indexPath.row] as! Album)
			}
		}
		super.tableView(tableView, didSelectRowAt: indexPath)
	}
}
