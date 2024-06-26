// 2020-04-28

import UIKit
import SwiftUI
import MusicKit
import MediaPlayer
import CoreData

@MainActor @Observable final class AlbumListState {
	@ObservationIgnored var albums: [Album] = AlbumListState.freshAlbums() {
		didSet { Database.renumber(albums) }
	}
	var current: State = .view {
		didSet { NotificationCenter.default.post(name: Self.changeEditingAlbums, object: nil) }
	}
	enum State {
		case view
		case editIndices(Set<Int>)
	}
}
extension AlbumListState {
	static let changeEditingAlbums = Notification.Name("LRChangeAlbumsForEditing")
	func rowIdentifiers() -> [AnyHashable] {
		return albums.map { $0.objectID }
	}
	static func freshAlbums() -> [Album] {
		return Collection.allFetched(sorted: false, context: Database.viewContext).first?.albums(sorted: true) ?? []
	}
}

// MARK: - Table view controller

final class AlbumsTVC: LibraryTVC {
	private let albumListState = AlbumListState()
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		albumListState.current = editing ? .editIndices([]) : .view
	}
	
	private lazy var arrangeButton = UIBarButtonItem(title: InterfaceText.sort, image: UIImage(systemName: "arrow.up.arrow.down"))
	private lazy var promoteButton = UIBarButtonItem(title: InterfaceText.moveUp, image: UIImage(systemName: "arrow.up"), primaryAction: UIAction { [weak self] _ in self?.promote() }, menu: UIMenu(children: [UIAction(title: InterfaceText.moveToTop, image: UIImage(systemName: "arrow.up.to.line")) { [weak self] _ in self?.float() }]))
	private lazy var demoteButton = UIBarButtonItem(title: InterfaceText.moveDown, image: UIImage(systemName: "arrow.down"), primaryAction: UIAction { [weak self] _ in self?.demote() }, menu: UIMenu(children: [UIAction(title: InterfaceText.moveToBottom, image: UIImage(systemName: "arrow.down.to.line")) { [weak self] _ in self?.sink() }]))
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		editingButtons = [editButtonItem, .flexibleSpace(), arrangeButton, .flexibleSpace(), promoteButton, .flexibleSpace(), demoteButton]
		arrangeButton.preferredMenuElementOrder = .fixed
		
		super.viewDidLoad()
		
		navigationItem.backButtonDisplayMode = .minimal
		tableView.separatorStyle = .none
		
		NotificationCenter.default.addObserverOnce(self, selector: #selector(activatedAlbum), name: AlbumRow.activatedAlbum, object: nil)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(refreshEditingButtons), name: AlbumListState.changeEditingAlbums, object: nil)
		__MainToolbar.shared.albumsTVC = WeakRef(self)
	}
	@objc private func activatedAlbum(notification: Notification) {
		guard let activated = notification.object as? Album else { return }
		push(activated)
	}
	private func push(_ album: Album) {
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
			let album = albumListState.albums[indexPath.row]
			cell.contentConfiguration = UIHostingConfiguration {
				AlbumRow(
					album: album,
					viewportWidth: size.width,
					viewportHeight: size.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom,
					albumListState: albumListState)
			}.margins(.all, .zero)
		}
	}
	
	func showCurrent() {
		guard
			let currentAlbumID = MPMusicPlayerController._system?.nowPlayingItem?.albumPersistentID,
			let currentAlbum = albumListState.albums.first(where: { album in
				currentAlbumID == album.albumPersistentID
			})
		else { return }
		// The current song might not be in our database, but the current `Album` is.
		navigationController?.popToRootViewController(animated: true)
		let indexPath = IndexPath(row: Int(currentAlbum.index), section: 0)
		tableView.scrollToRow(at: indexPath, at: .top, animated: true)
	}
	
	override func refreshLibraryItems() {
		Task {
			let oldRows = albumListState.rowIdentifiers()
			albumListState.albums = AlbumListState.freshAlbums()
			guard !albumListState.albums.isEmpty else {
				reflectNoAlbums()
				return
			}
			switch albumListState.current {
				case .view: break
				case .editIndices: albumListState.current = .editIndices([]) // If in editing mode, deselects everything and stays in editing mode
			}
			refreshEditingButtons() // If old view model was empty, enable “Edit” button
			guard await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers()) else { return }
			
			// Update the data within each row, which might be outdated.
			tableView.reconfigureRows(at: tableView.allIndexPaths())
		}
	}
	private func reflectNoAlbums() {
		tableView.deleteRows(at: tableView.allIndexPaths(), with: .middle)
		setEditing(false, animated: true) // Do this after updating the table view, not before, because this itself also updates the table view, expecting its row counts to be correct beforehand.
	}
	
	// MARK: - Editing
	
	@objc override func refreshEditingButtons() {
		super.refreshEditingButtons()
		editButtonItem.isEnabled = !albumListState.albums.isEmpty && MusicAuthorization.currentStatus == .authorized // If the user revokes access, we’re showing the placeholder, but the view model is probably non-empty.
		arrangeButton.isEnabled = {
			switch albumListState.current {
				case .view: return false
				case .editIndices(let selected):
					if selected.isEmpty { return true }
					return selected.sorted().isConsecutive()
			}
		}()
		arrangeButton.menu = newArrangeMenu()
		promoteButton.isEnabled = {
			switch albumListState.current {
				case .view: return false
				case .editIndices(let selected): return !selected.isEmpty
			}
		}()
		demoteButton.isEnabled = promoteButton.isEnabled
	}
	
	private func newArrangeMenu() -> UIMenu {
		let sections: [[ArrangeCommand]] = [
			[.album_recentlyAdded, .album_newest, .album_artist],
			[.random, .reverse],
		]
		let elementsGrouped: [[UIMenuElement]] = sections.map { section in
			section.map { command in
				command.newMenuElement(enabled: {
					guard
						indicesToArrange().count >= 2,
						!albumListState.albums.isEmpty
					else { return false }
					switch command {
						case .random, .reverse: return true
						case .song_track: return false
						case .album_recentlyAdded, .album_artist: return true
						case .album_newest:
							let toSort = indicesToArrange().map { albumListState.albums[$0] }
							return toSort.contains { nil != $0.releaseDateEstimate }
					}
				}()) { [weak self] in self?.arrange(by: command) }
			}
		}
		let inlineSubmenus = elementsGrouped.map {
			UIMenu(options: .displayInline, children: $0)
		}
		return UIMenu(children: inlineSubmenus)
	}
	private func arrange(by command: ArrangeCommand) {
		let oldRows = albumListState.rowIdentifiers()
		
		albumListState.albums = {
			let subjectedIndicesInOrder = indicesToArrange().sorted()
			let toSort = subjectedIndicesInOrder.map { albumListState.albums[$0] }
			let sorted = command.apply(to: toSort) as! [Album]
			var result = albumListState.albums
			subjectedIndicesInOrder.indices.forEach { counter in
				let replaceAt = subjectedIndicesInOrder[counter]
				let newItem = sorted[counter]
				result[replaceAt] = newItem
			}
			return result
		}()
		albumListState.current = .editIndices([])
		Task { let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers()) }
	}
	private func indicesToArrange() -> [Int] {
		switch albumListState.current {
			case .view: return []
			case .editIndices(let selected):
				guard selected.isEmpty else { return Array(selected) }
				return Array(albumListState.albums.indices)
		}
	}
	
	private func promote() {
		guard
			case let .editIndices(selected) = albumListState.current,
			let frontmostIndex = selected.min()
		else { return }
		
		let oldRows = albumListState.rowIdentifiers()
		let targetIndex = selected.sorted().isConsecutive() ? max(frontmostIndex - 1, 0) : frontmostIndex
		
		albumListState.current = .editIndices(Set(targetIndex ... (targetIndex + selected.count - 1)))
		var newAlbums = albumListState.albums
		newAlbums.move(fromOffsets: IndexSet(selected), toOffset: targetIndex)
		Database.renumber(newAlbums)
		albumListState.albums = newAlbums
		Task {
			let _ = await moveRows(
				oldIdentifiers: oldRows,
				newIdentifiers: albumListState.rowIdentifiers(),
				runningBeforeContinuation: {
					self.tableView.scrollToRow(at: IndexPath(row: targetIndex, section: 0), at: .middle, animated: true)
				})
		}
	}
	private func demote() {
		guard
			case let .editIndices(selected) = albumListState.current,
			let backmostIndex = selected.max()
		else { return }
		
		let oldRows = albumListState.rowIdentifiers()
		let targetIndex = selected.sorted().isConsecutive() ? min(backmostIndex + 1, albumListState.albums.count - 1) : backmostIndex
		
		albumListState.current = .editIndices(Set((targetIndex - selected.count + 1) ... targetIndex))
		var newAlbums = albumListState.albums
		newAlbums.move(fromOffsets: IndexSet(selected), toOffset: targetIndex + 1) // This method puts the elements before the `toOffset` index.
		Database.renumber(newAlbums)
		albumListState.albums = newAlbums
		Task {
			let _ = await moveRows(
				oldIdentifiers: oldRows,
				newIdentifiers: albumListState.rowIdentifiers(),
				runningBeforeContinuation: {
					self.tableView.scrollToRow(at: IndexPath(row: targetIndex, section: 0), at: .middle, animated: true)
				})
		}
	}
	
	private func float() {
		guard case let .editIndices(selected) = albumListState.current else { return }
		
		let oldRows = albumListState.rowIdentifiers()
		var newAlbums = albumListState.albums
		
		albumListState.current = .editIndices([])
		newAlbums.move(fromOffsets: IndexSet(selected), toOffset: 0)
		Database.renumber(newAlbums)
		albumListState.albums = newAlbums
		// Don’t use `refreshLibraryItems`, because if no rows moved, that doesn’t animate deselecting the rows.
		Task { let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers()) }
	}
	private func sink() {
		guard case let .editIndices(selected) = albumListState.current else { return }
		
		let oldRows = albumListState.rowIdentifiers()
		var newAlbums = albumListState.albums
		
		albumListState.current = .editIndices([])
		newAlbums.move(fromOffsets: IndexSet(selected), toOffset: newAlbums.count)
		Database.renumber(newAlbums)
		albumListState.albums = newAlbums
		Task { let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers()) }
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
			if albumListState.albums.isEmpty {
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
		return albumListState.albums.count
	}
	
	override func tableView(
		_ tableView: UITableView, cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		// The cell in the storyboard is completely default except for the reuse identifier.
		let cell = tableView.dequeueReusableCell(withIdentifier: "Album Card", for: indexPath)
		return configuredCellForAlbum(cell: cell, album: albumListState.albums[indexPath.row])
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
				albumListState: albumListState)
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
}
