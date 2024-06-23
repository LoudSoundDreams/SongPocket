// 2020-04-28

import UIKit
import SwiftUI
import MusicKit
import MediaPlayer
import CoreData

@MainActor private struct AlbumsViewModel {
	var albums: [Album] = Collection.allFetched(sorted: false, context: Database.viewContext).first?.albums(sorted: true) ?? [] {
		didSet { Database.renumber(albums) }
	}
	func withRefreshedData() -> Self { return Self() }
	func rowIdentifiers() -> [AnyHashable] {
		return albums.map { $0.objectID }
	}
}

@Observable final class AlbumsTVCStatus {
	var editingAlbumIndices: Set<Int>? = nil
}

// MARK: - Table view controller

final class AlbumsTVC: LibraryTVC {
	private var albumsViewModel = AlbumsViewModel()
	
	private let tvcStatus = AlbumsTVCStatus()
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		tvcStatus.editingAlbumIndices = editing ? [] : nil
	}
	
	private lazy var arrangeAlbumsButton = UIBarButtonItem(title: InterfaceText.sort, image: UIImage(systemName: "arrow.up.arrow.down"))
	private lazy var floatAlbumsButton = UIBarButtonItem(title: InterfaceText.moveToTop, image: UIImage(systemName: "arrow.up.to.line"), primaryAction: UIAction { [weak self] _ in self?.floatSelected() })
	private lazy var sinkAlbumsButton = UIBarButtonItem(title: InterfaceText.moveToBottom, image: UIImage(systemName: "arrow.down.to.line"), primaryAction: UIAction { [weak self] _ in self?.sinkSelected() })
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		editingButtons = [editButtonItem, .flexibleSpace(), arrangeAlbumsButton, .flexibleSpace(), floatAlbumsButton, .flexibleSpace(), sinkAlbumsButton]
		arrangeAlbumsButton.preferredMenuElementOrder = .fixed
		
		super.viewDidLoad()
		
		navigationItem.backButtonDisplayMode = .minimal
		tableView.separatorStyle = .none
		
		NotificationCenter.default.addObserverOnce(self, selector: #selector(activatedAlbum), name: AlbumRow.activatedAlbum, object: nil)
		__MainToolbar.shared.albumsTVC = WeakRef(self)
	}
	@objc private func activatedAlbum(notification: Notification) {
		guard let activated = notification.object as? Album else { return }
		pushAlbum(activated)
	}
	private func pushAlbum(_ album: Album) {
		navigationController?.pushViewController({
			let songsTVC = UIStoryboard(name: "SongsTVC", bundle: nil).instantiateInitialViewController() as! SongsTVC
			songsTVC.songsViewModel = SongsViewModel(album: album)
			return songsTVC
		}(), animated: true)
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
					viewportWidth: size.width,
					viewportHeight: size.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom,
					albumsTVCStatus: tvcStatus)
			}.margins(.all, .zero)
		}
	}
	
	func showCurrentAlbum() {
		guard
			let currentAlbumID = MPMusicPlayerController._system?.nowPlayingItem?.albumPersistentID,
			let currentAlbum = albumsViewModel.albums.first(where: { album in
				currentAlbumID == album.albumPersistentID
			})
		else { return }
		// The current song might not be in our database, but the current `Album` is.
		navigationController?.popToRootViewController(animated: true)
		// TO DO: Wait until this view appears before scrolling.
		let indexPath = IndexPath(row: Int(currentAlbum.index), section: 0)
		tableView.scrollToRow(at: indexPath, at: .top, animated: true)
	}
	
	override func refreshLibraryItems() {
		Task {
			let oldRows = albumsViewModel.rowIdentifiers()
			albumsViewModel = albumsViewModel.withRefreshedData()
			guard !albumsViewModel.albums.isEmpty else {
				reflectNoAlbums()
				return
			}
			guard await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumsViewModel.rowIdentifiers()) else { return }
			
			// Update the data within each row, which might be outdated.
			tableView.reconfigureRows(at: tableView.allIndexPaths())
		}
	}
	private func reflectNoAlbums() {
		tableView.deleteRows(at: tableView.allIndexPaths(), with: .middle)
		setEditing(false, animated: true) // Do this after updating the table view, not before, because this itself also updates the table view, expecting its row counts to be correct beforehand.
	}
	
	// MARK: - Editing
	
	override func refreshEditingButtons() {
		super.refreshEditingButtons()
		editButtonItem.isEnabled = !albumsViewModel.albums.isEmpty && MusicAuthorization.currentStatus == .authorized // If the user revokes access, we’re showing the placeholder, but the view model is probably non-empty.
		arrangeAlbumsButton.isEnabled = allowsArrange()
		arrangeAlbumsButton.menu = createArrangeMenu()
		floatAlbumsButton.isEnabled = allowsFloatAndSink()
		sinkAlbumsButton.isEnabled = allowsFloatAndSink()
	}
	
	private func allowsArrange() -> Bool {
		guard !albumsViewModel.albums.isEmpty else { return false }
		let selected = tableView.selectedIndexPaths
		if selected.isEmpty { return true }
		return selected.map { $0.row }.sorted().isConsecutive()
	}
	private func createArrangeMenu() -> UIMenu {
		let sections: [[ArrangeCommand]] = [
			[.album_recentlyAdded, .album_newest, .album_artist],
			[.random, .reverse],
		]
		let elementsGrouped: [[UIMenuElement]] = sections.map { section in
			section.map { command in
				command.createMenuElement(enabled: {
					guard selectedOrAllIndices().count >= 2 else { return false }
					switch command {
						case .random, .reverse: return true
						case .song_track: return false
						case .album_recentlyAdded, .album_artist: return true
						case .album_newest:
							let toSort = selectedOrAllIndices().map { albumsViewModel.albums[$0] }
							return toSort.contains { nil != $0.releaseDateEstimate }
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
		let oldRows = albumsViewModel.rowIdentifiers()
		albumsViewModel.albums = {
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
		Task { let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumsViewModel.rowIdentifiers()) }
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
		let oldRows = albumsViewModel.rowIdentifiers()
		var newAlbums = albumsViewModel.albums
		let unorderedIndices = tableView.selectedIndexPaths.map { $0.row }
		newAlbums.move(fromOffsets: IndexSet(unorderedIndices), toOffset: 0)
		Database.renumber(newAlbums)
		albumsViewModel.albums = newAlbums
		// Don’t use `refreshLibraryItems`, because if no rows moved, that doesn’t animate deselecting the rows.
		Task { let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumsViewModel.rowIdentifiers()) }
	}
	private func sinkSelected() {
		let oldRows = albumsViewModel.rowIdentifiers()
		var newAlbums = albumsViewModel.albums
		let unorderedIndices = tableView.selectedIndexPaths.map { $0.row }
		newAlbums.move(fromOffsets: IndexSet(unorderedIndices), toOffset: newAlbums.count)
		Database.renumber(newAlbums)
		albumsViewModel.albums = newAlbums
		Task { let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumsViewModel.rowIdentifiers()) }
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
						Button {
							let musicURL = URL(string: "music://")!
							UIApplication.shared.open(musicURL)
						} label: {
							Image(systemName: "plus")
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
		return configuredCellForAlbum(cell: cell, album: albumsViewModel.albums[indexPath.row])
	}
	private func configuredCellForAlbum(cell: UITableViewCell, album: Album) -> UITableViewCell {
		cell.backgroundColor = .clear
		cell.selectedBackgroundView = {
			let result = UIView()
			result.backgroundColor = .tintColor.withAlphaComponent(.oneHalf)
			return result
		}()
		cell.contentConfiguration = UIHostingConfiguration {
			AlbumRow(
				album: album,
				viewportWidth: view.frame.width,
				viewportHeight: {
					let height = view.frame.height
					let topInset = view.safeAreaInsets.top
					let bottomInset = view.safeAreaInsets.bottom
					return height - topInset - bottomInset
				}(),
				albumsTVCStatus: tvcStatus)
		}.margins(.all, .zero)
		return cell
	}
	
	override func tableView(
		_ tableView: UITableView, willSelectRowAt indexPath: IndexPath
	) -> IndexPath? {
		return nil
	}
	
	override func tableView(
		_ tableView: UITableView, canEditRowAt indexPath: IndexPath
	) -> Bool {
		return false
	}
	override func tableView( // TO DO: Delete
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
