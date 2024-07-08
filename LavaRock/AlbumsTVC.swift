// 2020-04-28

import UIKit
import SwiftUI
import MusicKit
import MediaPlayer
import CoreData

@MainActor @Observable final class AlbumListState {
	@ObservationIgnored fileprivate var items: [Item] = AlbumListState.freshAlbums().map { .album($0) } // Retain old items until we explicitly refresh them, so we can diff them for updating the table view.
	var expansion: Expansion = .collapsed
	var selectMode: SelectMode = .view { didSet {
		switch selectMode {
			case .view: break
			case .selectAlbums: NotificationCenter.default.post(name: Self.selectingAlbums, object: self)
		}
	}}
}
extension AlbumListState {
	fileprivate enum Item {
		case album(Album)
		case song(Song)
	}
	fileprivate func refreshItems() {
		items = {
			let albums = Self.freshAlbums()
			switch expansion {
				case .collapsed: return albums.map { .album($0) }
				case .expanded(let expandedAlbumID):
					guard let expandedAlbum = albums.first(where: { album in
						expandedAlbumID == album.albumPersistentID
					}) else {
						expansion = .collapsed
						return albums.map { .album($0) }
					}
					let inlineSongs = expandedAlbum.songs(sorted: true)
					var result: [Item] = albums.map { .album($0) }
					result.insert(
						contentsOf: inlineSongs.map { .song($0) },
						at: Int(expandedAlbum.index) + 1)
					return result
			}
		}()
	}
	private static func freshAlbums() -> [Album] {
		return Database.viewContext.fetchPlease(Album.fetchRequest_sorted())
	}
	fileprivate func rowIdentifiers() -> [AnyHashable] {
		return items.map { switch $0 {
			case .album(let album): return album.objectID
			case .song(let song): return song.objectID
		}}
	}
	
	enum Expansion {
		case collapsed
		case expanded(AlbumID)
	}
	
	enum SelectMode {
		case view
		case selectAlbums(Set<AlbumID>)
	}
	static let selectingAlbums = Notification.Name("LRSelectingAlbums")
}

// MARK: - Table view controller

final class AlbumsTVC: LibraryTVC {
	private let albumListState = AlbumListState()
	
	private let selectButton = UIBarButtonItem()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = UIColor(.grey_oneEighth)
		tableView.separatorStyle = .none
		endSelecting()
		
		selectButton.isEnabled = allowsSelect()
		navigationItem.backButtonDisplayMode = .minimal
		
		NotificationCenter.default.addObserverOnce(self, selector: #selector(mergedChanges), name: MusicRepo.mergedChanges, object: nil)
		__MainToolbar.shared.albumsTVC = WeakRef(self)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(expandAlbumID), name: AlbumRow.expandAlbumID, object: nil)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(collapse), name: AlbumRow.collapse, object: nil)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(album_reflectSelected), name: AlbumListState.selectingAlbums, object: albumListState)
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
					ContentUnavailableView {} description: { Text(InterfaceText.welcome_message)
					} actions: {
						Button(InterfaceText.welcome_button) {
							Task { await AppleMusic.requestAccess() }
						}
					}
				}.margins(.all, .zero) // As of iOS 17.5 developer beta 1, this prevents the content from sometimes jumping vertically.
			}
			if albumListState.items.isEmpty {
				return UIHostingConfiguration {
					ContentUnavailableView {} actions: {
						Button {
							let musicURL = URL(string: "music://")!
							UIApplication.shared.open(musicURL)
						} label: { Image(systemName: "plus") }
					}
				}
			}
			return nil
		}()
	}
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard MusicAuthorization.currentStatus == .authorized else { return 0 }
		return albumListState.items.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch albumListState.items[indexPath.row] {
			case .album(let rowAlbum):
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(withIdentifier: "Album Card", for: indexPath)
				return cellForAlbum(cell: cell, album: rowAlbum)
			case .song(let rowSong):
				switch albumListState.expansion {
					case .collapsed: return UITableViewCell() // Should never run
					case .expanded(let expandedAlbumID):
						let cell = tableView.dequeueReusableCell(withIdentifier: "Album Card", for: indexPath) // TO DO: Dequeue a different cell
						cell.backgroundColor = .clear
						cell.selectedBackgroundView = {
							let result = UIView()
							result.backgroundColor = .tintColor.withAlphaComponent(.oneHalf)
							return result
						}()
						cell.contentConfiguration = UIHostingConfiguration {
							SongRow(
								song: rowSong,
								albumID: expandedAlbumID,
								songListState: __songListState)
						}.margins(.all, .zero)
						return cell
				}
		}
	}
	private let __songListState = SongListState()
	private func cellForAlbum(cell: UITableViewCell, album: Album) -> UITableViewCell {
		cell.backgroundColor = .clear
		cell.selectedBackgroundView = {
			let result = UIView()
			result.backgroundColor = .tintColor.withAlphaComponent(.oneHalf)
			return result
		}()
		cell.contentConfiguration = UIHostingConfiguration {
			AlbumRow(
				albumID: album.albumPersistentID,
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
	
	override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? { return nil }
	
	// MARK: - Events
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		Task {
			if needsRefreshLibraryItems {
				needsRefreshLibraryItems = false
				await refreshLibraryItems()
			}
			
			if needsScrollToCurrent {
				needsScrollToCurrent = false
				scrollToCurrent()
			}
		}
	}
	
	override func viewWillTransition(
		to size: CGSize,
		with coordinator: UIViewControllerTransitionCoordinator
	) {
		super.viewWillTransition(to: size, with: coordinator)
		
		tableView.allIndexPaths().forEach { indexPath in // Don’t use `indexPathsForVisibleRows`, because that excludes cells that underlap navigation bars and toolbars.
			guard let cell = tableView.cellForRow(at: indexPath) else { return }
			switch albumListState.items[indexPath.row] {
				case .song: return
				case .album(let rowAlbum):
					cell.contentConfiguration = UIHostingConfiguration {
						AlbumRow(
							albumID: rowAlbum.albumPersistentID,
							viewportWidth: size.width,
							viewportHeight: size.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom,
							albumListState: albumListState)
					}.margins(.all, .zero)
			}
		}
	}
	
	@objc private func mergedChanges() {
		guard nil != view.window else {
			needsRefreshLibraryItems = true
			return
		}
		Task { await refreshLibraryItems() }
	}
	private var needsRefreshLibraryItems = false
	private func refreshLibraryItems() async {
		// WARNING: Is the user in the middle of a content-dependent interaction, like moving or renaming items? If so, wait until they finish before proceeding, or abort that interaction.
		
		let oldRows = albumListState.rowIdentifiers()
		albumListState.refreshItems()
		selectButton.isEnabled = allowsSelect()
		switch albumListState.selectMode {
			case .view: break
			case .selectAlbums(let selectedAlbumIDs):
				let newSelected: Set<AlbumID> = Set(albumListState.items.compactMap { switch $0 {
					case .song: return nil
					case .album(let album):
						let albumID = album.albumPersistentID
						guard selectedAlbumIDs.contains(albumID) else { return nil }
						return albumID
				}})
				albumListState.selectMode = .selectAlbums(newSelected)
		}
		guard !albumListState.items.isEmpty else {
			reflectNoAlbums()
			return
		}
		// TO DO: Keep current content visible
		guard await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers()) else { return }
		
		// Update the data within each row, which might be outdated.
		tableView.reconfigureRows(at: tableView.allIndexPaths())
	}
	private func reflectNoAlbums() {
		tableView.deleteRows(at: tableView.allIndexPaths(), with: .middle)
		endSelecting()
	}
	
	func showCurrent() {
		guard nil != view.window else {
			needsScrollToCurrent = true
			navigationController?.popToViewController(self, animated: true)
			return
		}
		scrollToCurrent()
	}
	private var needsScrollToCurrent = false
	private func scrollToCurrent() {
		guard let uInt64 = MPMusicPlayerController._system?.nowPlayingItem?.albumPersistentID else { return }
		let currentAlbumID = AlbumID(bitPattern: uInt64)
		guard let currentRow = albumListState.items.firstIndex(where: { switch $0 {
			case .song: return false
			case .album(let album): return currentAlbumID == album.albumPersistentID
		}}) else { return }
		// The current song might not be in our database, but the current `Album` is.
		let indexPath = IndexPath(row: currentRow, section: 0)
		tableView.scrollToRow(at: indexPath, at: .top, animated: true)
	}
	
	@objc private func expandAlbumID(notification: Notification) {
		guard let albumIDToOpen = notification.object as? AlbumID else { return }
		let oldRows = albumListState.rowIdentifiers()
		
		albumListState.expansion = .expanded(albumIDToOpen)
		albumListState.refreshItems()
		Task {
			let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers(), runningBeforeContinuation: {
				self.tableView.scrollToRow(
					at: IndexPath(
						row: self.albumListState.items.firstIndex(where: { switch $0 {
							case .album(let album): return albumIDToOpen == album.albumPersistentID
							case .song: return false
						}})!,
						section: 0),
					at: .top,
					animated: true)
			})
		}
	}
	@objc private func collapse() {
		let oldRows = albumListState.rowIdentifiers()
		
		albumListState.expansion = .collapsed
		albumListState.refreshItems()
		Task { let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers()) }
	}
	
	// MARK: - Editing
	
	private func allowsSelect() -> Bool {
		return !albumListState.items.isEmpty && MusicAuthorization.currentStatus == .authorized // If the user revokes access, we’re showing the placeholder, but the view model is probably non-empty.
	}
	
	private func beginSelecting() {
		setToolbarItems([selectButton, .flexibleSpace(), album_arranger, .flexibleSpace(), album_promoter, .flexibleSpace(), album_demoter], animated: true)
		withAnimation {
			albumListState.selectMode = .selectAlbums([])
		}
		selectButton.primaryAction = UIAction(title: InterfaceText.done, image: Self.endSelectingImage) { [weak self] _ in self?.endSelecting() }
	}
	private func endSelecting() {
		Database.viewContext.savePlease()
		
		setToolbarItems([selectButton] + __MainToolbar.shared.barButtonItems, animated: true)
		withAnimation {
			albumListState.selectMode = .view
		}
		selectButton.primaryAction = UIAction(title: InterfaceText.select, image: Self.beginSelectingImage) { [weak self] _ in self?.beginSelecting() }
	}
	
	private let album_arranger = UIBarButtonItem(title: InterfaceText.sort, image: UIImage(systemName: "arrow.up.arrow.down"))
	private lazy var album_promoter = UIBarButtonItem(title: InterfaceText.moveUp, image: UIImage(systemName: "chevron.up"), primaryAction: UIAction { [weak self] _ in self?.album_promote() }, menu: UIMenu(children: [UIAction(title: InterfaceText.toTop, image: UIImage(systemName: "arrow.up.to.line")) { [weak self] _ in self?.album_float() }]))
	private lazy var album_demoter = UIBarButtonItem(title: InterfaceText.moveDown, image: UIImage(systemName: "chevron.down"), primaryAction: UIAction { [weak self] _ in self?.album_demote() }, menu: UIMenu(children: [UIAction(title: InterfaceText.toBottom, image: UIImage(systemName: "arrow.down.to.line")) { [weak self] _ in self?.album_sink() }]))
	
	@objc private func album_reflectSelected() {
		album_arranger.isEnabled = false
		album_arranger.preferredMenuElementOrder = .fixed
		album_arranger.menu = nil
		album_promoter.isEnabled = false
		album_demoter.isEnabled = album_promoter.isEnabled
	}
	
	private func album_promote() {
	}
	private func album_demote() {
	}
	
	private func album_float() {
	}
	private func album_sink() {
	}
}
