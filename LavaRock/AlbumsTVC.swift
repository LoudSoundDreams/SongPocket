// 2020-04-28

import UIKit
import SwiftUI
import MusicKit
import MediaPlayer

@MainActor @Observable final class AlbumListState {
	@ObservationIgnored fileprivate var listItems: [Item] = AlbumListState.freshAlbums().map { .album($0) }
	var expansion: Expansion = .collapsed { didSet {
		NotificationCenter.default.post(name: Self.expansionChanged, object: self)
	}}
	var selectMode: SelectMode = .view(nil) { didSet {
		NotificationCenter.default.post(name: Self.selectionChanged, object: self)
	}}
	var viewportSize: (width: CGFloat, height: CGFloat) = (.zero, .zero)
}
extension AlbumListState {
	fileprivate enum Item {
		case album(ZZZAlbum)
		case song(ZZZSong)
	}
	fileprivate func refreshItems() {
		listItems = {
			let albums = Self.freshAlbums()
			switch expansion {
				case .collapsed: return albums.map { .album($0) }
				case .expanded(let idExpanded):
					// If we removed the expanded album, go to collapsed mode.
					guard let iExpandedAlbum = albums.firstIndex(where: { album in
						idExpanded == album.albumPersistentID
					}) else {
						expansion = .collapsed
						return albums.map { .album($0) }
					}
					
					let songs: [Item] = albums[iExpandedAlbum].songs(sorted: true).map { .song($0) }
					var result: [Item] = albums.map { .album($0) }
					result.insert(contentsOf: songs, at: iExpandedAlbum + 1)
					return result
			}
		}()
		
		// In case we removed items the user was doing something with.
		switch selectMode {
			case .view(let idActivated):
				if let idActivated, songs(with: [idActivated]).isEmpty {
					selectMode = .view(nil)
				}
			case .selectAlbums(let idsSelected):
				let selectable: Set<AlbumID> = Set(
					albums(with: idsSelected).map { $0.albumPersistentID }
				)
				if idsSelected != selectable {
					selectMode = .selectAlbums(selectable)
				}
			case .selectSongs(let idsSelected):
				let selectable: Set<SongID> = Set(
					songs(with: idsSelected).map { $0.persistentID }
				)
				if idsSelected != selectable{
					selectMode = .selectSongs(selectable)
				}
		}
	}
	private static func freshAlbums() -> [ZZZAlbum] {
		guard MusicAuthorization.currentStatus == .authorized else { return [] }
		return ZZZDatabase.viewContext.fetchPlease(ZZZAlbum.fetchRequest_sorted())
	}
	fileprivate func rowIdentifiers() -> [AnyHashable] {
		return listItems.map { switch $0 {
			case .album(let album): return album.objectID
			case .song(let song): return song.objectID
		}}
	}
	fileprivate func albums(with chosenIDs: Set<AlbumID>? = nil) -> [ZZZAlbum] {
		return listItems.compactMap { switch $0 {
			case .song: return nil
			case .album(let album):
				guard let chosenIDs else { return album }
				guard chosenIDs.contains(album.albumPersistentID) else { return nil }
				return album
		}}
	}
	fileprivate func songs(with chosenIDs: Set<SongID>? = nil) -> [ZZZSong] {
		return listItems.compactMap { switch $0 {
			case .album: return nil
			case .song(let song):
				guard let chosenIDs else { return song }
				guard chosenIDs.contains(song.persistentID) else { return nil }
				return song
		}}
	}
	
	enum Expansion: Equatable {
		case collapsed
		case expanded(AlbumID)
	}
	static let expansionChanged = Notification.Name("LRAlbumExpandingOrCollapsing")
	
	enum SelectMode: Equatable {
		case view(SongID?)
		case selectAlbums(Set<AlbumID>)
		case selectSongs(Set<SongID>) // Should always be within the same album.
	}
	static let selectionChanged = Notification.Name("LRSelectModeOrSelectionChanged")
}

// MARK: - View controller

final class AlbumsTVC: LibraryTVC {
	private let albumListState = AlbumListState()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = UIColor(Color(white: .oneEighth))
		tableView.separatorStyle = .none
		reflectSelection()
		bEllipsis.preferredMenuElementOrder = .fixed
		bEllipsis.menu = menuSortAlbums()
		
		NotificationCenter.default.addObserver(self, selector: #selector(refresh_bBeginSelecting), name: Librarian.willMerge, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(refresh_bBeginSelecting), name: Librarian.didMerge, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(refreshLibraryItems), name: Librarian.didMerge, object: nil)
		Remote.shared.albumsTVC = WeakRef(self)
		NotificationCenter.default.addObserver(self, selector: #selector(reflectExpansion), name: AlbumListState.expansionChanged, object: albumListState)
		NotificationCenter.default.addObserver(self, selector: #selector(confirmPlay), name: SongRow.confirmPlaySongID, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(reflectSelection), name: AlbumListState.selectionChanged, object: albumListState)
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
					ContentUnavailableView {} description: { Text(InterfaceText._messageWelcome)
					} actions: {
						Button(InterfaceText.continue_) {
							Task {
								switch MusicAuthorization.currentStatus {
									case .authorized: break // Should never run
									case .notDetermined:
										switch await MusicAuthorization.request() {
											case .denied, .restricted, .notDetermined: break
											case .authorized: LavaRock.integrateAppleMusic()
											@unknown default: break
										}
									case .denied, .restricted:
										if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
											let _ = await UIApplication.shared.open(settingsURL)
										}
									@unknown default: break
								}
							}
						}
					}
				}.margins(.all, .zero) // As of iOS 17.5 developer beta 1, this prevents the content from sometimes jumping vertically.
			}
			if albumListState.listItems.isEmpty {
				return UIHostingConfiguration {
					ContentUnavailableView {} actions: {
						Button { Librarian.openAppleMusic() } label: { Image(systemName: "plus") }
					}
				}.margins(.all, .zero)
			}
			return nil
		}()
	}
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if !hasSetOnscreenRowIdentifiers {
			hasSetOnscreenRowIdentifiers = true
			idsRowsOnscreen = albumListState.rowIdentifiers()
		}
		return albumListState.listItems.count
	}
	private var hasSetOnscreenRowIdentifiers = false
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch albumListState.listItems[indexPath.row] {
			case .album(let rowAlbum):
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(withIdentifier: "Album Card", for: indexPath)
				cell.backgroundColor = .clear
				cell.selectedBackgroundView = {
					let result = UIView()
					result.backgroundColor = .tintColor.withAlphaComponent(.oneHalf)
					return result
				}()
				albumListState.viewportSize = (
					width: view.frame.width,
					height: view.frame.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom)
				cell.contentConfiguration = UIHostingConfiguration {
					AlbumRow(idAlbum: rowAlbum.albumPersistentID, listState: albumListState)
				}.margins(.all, .zero)
				return cell
			case .song(let rowSong):
				switch albumListState.expansion {
					case .collapsed: return UITableViewCell() // Should never run
					case .expanded(let idExpanded):
						// The cell in the storyboard is completely default except for the reuse identifier.
						let cell = tableView.dequeueReusableCell(withIdentifier: "Inline Song", for: indexPath)
						cell.backgroundColor = .clear
						cell.selectedBackgroundView = {
							let result = UIView()
							result.backgroundColor = .tintColor.withAlphaComponent(.oneHalf)
							return result
						}()
						cell.contentConfiguration = UIHostingConfiguration {
							SongRow(idSong: rowSong.persistentID, idAlbum: idExpanded, listState: albumListState)
						}.margins(.all, .zero)
						return cell
				}
		}
	}
	
	override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? { return nil }
	
	// MARK: - Events
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		albumListState.viewportSize = (width: size.width, height: size.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom)
	}
	
	@objc private func refreshLibraryItems() {
		Task {
			albumListState.refreshItems()
			switch albumListState.expansion {
				case .collapsed: bEllipsis.menu = menuSortAlbums()
				case .expanded: bEllipsis.menu = menuSortSongs()
			}
			guard await applyIDsRows(albumListState.rowIdentifiers()) else { return }
		}
	}
	
	func showCurrent() {
		guard
			let idSong = MPMusicPlayerController.idSongCurrent,
			let song = ZZZDatabase.viewContext.fetchSong(mpID: idSong),
			let idAlbum = song.container?.albumPersistentID
		else { return }
		guard let rowAlbum = albumListState.listItems.firstIndex(where: { switch $0 {
			case .song: return false
			case .album(let album): return idAlbum == album.albumPersistentID
		}}) else { return }
		tableView.performBatchUpdates {
			tableView.scrollToRow(at: IndexPath(row: rowAlbum, section: 0), at: .top, animated: true)
		} completion: { _ in
			self.albumListState.expansion = .expanded(idAlbum)
		}
	}
	
	@objc private func reflectExpansion() {
		switch albumListState.expansion {
			case .collapsed:
				Task {
					albumListState.refreshItems() // Immediately proceed to update the table view; don’t wait until a separate `Task`. As of iOS 17.6 developer beta 2, `UITableView` has a bug where it might call `cellForRowAt` with invalidly large `IndexPath`s: it’s trying to draw subsequent rows after we change a cell’s height in a `UIHostingConfiguration`, but forgetting to call `numberOfRowsInSection` first.
					bEllipsis.menu = menuSortAlbums()
					let _ = await applyIDsRows(albumListState.rowIdentifiers())
				}
			case .expanded(let idToExpand):
				Task {
					guard albumListState.albums().contains(where: { idToExpand == $0.albumPersistentID }) else { return }
					albumListState.refreshItems()
					bEllipsis.menu = menuSortSongs()
					let _ = await applyIDsRows(albumListState.rowIdentifiers(), runningBeforeContinuation: {
						let rowTarget: Int = self.albumListState.listItems.firstIndex(where: { switch $0 {
							case .song: return false
							case .album(let album): return idToExpand == album.albumPersistentID
						}})!
						self.tableView.scrollToRow(at: IndexPath(row: rowTarget, section: 0), at: .top, animated: true)
					})
				}
		}
	}
	
	@objc private func reflectSelection() {
		switch albumListState.selectMode {
			case .view(let idActivated):
				setToolbarItems([bBeginSelecting, .flexibleSpace(), Remote.shared.bRemote, .flexibleSpace(), bEllipsis], animated: true)
				switch albumListState.expansion {
					case .collapsed: bEllipsis.menu = menuSortAlbums()
					case .expanded: bEllipsis.menu = menuSortSongs()
				}
				if idActivated == nil {
					dismiss(animated: true) // In case “confirm play” action sheet is presented.
				}
			case .selectAlbums(let idsSelected):
				setToolbarItems([bEndSelecting, .flexibleSpace(), bPromoteAlbum, .flexibleSpace(), bDemoteAlbum, .flexibleSpace(), bEllipsis], animated: true)
				bEllipsis.menu = menuSortAlbums() // In case it’s open.
				bPromoteAlbum.isEnabled = !idsSelected.isEmpty
				bDemoteAlbum.isEnabled = bPromoteAlbum.isEnabled
			case .selectSongs(let idsSelected):
				setToolbarItems([bEndSelecting, .flexibleSpace(), bPromoteSong, .flexibleSpace(), bDemoteSong, .flexibleSpace(), bEllipsis], animated: true)
				bEllipsis.menu = menuSortSongs()
				bPromoteSong.isEnabled = !idsSelected.isEmpty
				bDemoteSong.isEnabled = bPromoteSong.isEnabled
		}
	}
	
	@objc private func confirmPlay(notification: Notification) {
		guard
			let idActivated = notification.object as? SongID,
			let popoverSource: UIView = { () -> UIView? in
				guard let rowActivated = albumListState.listItems.firstIndex(where: { switch $0 {
					case .album: return false
					case .song(let song): return idActivated == song.persistentID
				}}) else { return nil }
				return tableView.cellForRow(at: IndexPath(row: rowActivated, section: 0))
			}()
		else { return }
		
		albumListState.selectMode = .view(idActivated) // The UI is clearer if we leave the row selected while the action sheet is onscreen. You must eventually deselect the row in every possible scenario after this moment.
		
		let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		actionSheet.popoverPresentationController?.sourceView = popoverSource
		actionSheet.addAction(
			UIAlertAction(title: InterfaceText.startPlaying, style: .default) { _ in
				Task {
					self.albumListState.selectMode = .view(nil)
					
					guard
						let songActivated = self.albumListState.songs(with: [idActivated]).first,
						let albumActivated = songActivated.container
					else { return }
					
					ApplicationMusicPlayer._shared?.playNow(
						albumActivated.songs(sorted: true).map { $0.persistentID },
						startingAt: songActivated.persistentID)
				}
			}
			// I want to silence VoiceOver after you choose actions that start playback, but `UIAlertAction.accessibilityTraits = .startsMediaSession` doesn’t do it.)
		)
		actionSheet.addAction(
			UIAlertAction(title: InterfaceText.cancel, style: .cancel) { _ in
				self.albumListState.selectMode = .view(nil)
			}
		)
		present(actionSheet, animated: true)
	}
	
	// MARK: - Editing
	
	private lazy var bBeginSelecting = UIBarButtonItem(primaryAction: UIAction(title: InterfaceText.select, image: UIImage(systemName: "checkmark.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor))) { [weak self] _ in
		guard let self else { return }
		switch albumListState.expansion {
			case .collapsed:
				withAnimation {
					self.albumListState.selectMode = .selectAlbums([])
				}
			case .expanded:
				withAnimation {
					self.albumListState.selectMode = .selectSongs([])
				}
		}
	})
	@objc private func refresh_bBeginSelecting() {
		bBeginSelecting.isEnabled = !Librarian.shared.isMerging
	}
	
	private lazy var bEndSelecting = UIBarButtonItem(primaryAction: UIAction(title: InterfaceText.done, image: UIImage(systemName: "checkmark.circle.fill")) { [weak self] _ in self?.endSelecting_animated() })
	private func endSelecting_animated() {
		withAnimation {
			self.albumListState.selectMode = .view(nil)
		}
	}
	
	private let bEllipsis = UIBarButtonItem(title: InterfaceText.more, image: UIImage(systemName: "ellipsis.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor)))
	
	private lazy var bPromoteAlbum = UIBarButtonItem(primaryAction: aPromoteAlbum, menu: UIMenu(children: [aFloatAlbum]))
	private lazy var bDemoteAlbum = UIBarButtonItem(primaryAction: aDemoteAlbum, menu: UIMenu(children: [aSinkAlbum]))
	
	private lazy var aPromoteAlbum = UIAction(title: InterfaceText.moveUp, image: UIImage(systemName: "arrow.up.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor))) { [weak self] _ in self?.promoteAlbums() }
	private lazy var aDemoteAlbum = UIAction(title: InterfaceText.moveDown, image: UIImage(systemName: "arrow.down.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor))) { [weak self] _ in self?.demoteAlbums() }
	private lazy var aFloatAlbum = UIAction(title: InterfaceText.toTop, image: UIImage(systemName: "arrow.up.to.line")) { [weak self] _ in self?.floatAlbums() }
	private lazy var aSinkAlbum = UIAction(title: InterfaceText.toBottom, image: UIImage(systemName: "arrow.down.to.line")) { [weak self] _ in self?.sinkAlbums() }
	
	private lazy var bPromoteSong = UIBarButtonItem(primaryAction: aPromoteSong, menu: UIMenu(children: [aFloatSong]))
	private lazy var bDemoteSong = UIBarButtonItem(primaryAction: aDemoteSong, menu: UIMenu(children: [aSinkSong]))
	
	private lazy var aPromoteSong = UIAction(title: InterfaceText.moveUp, image: UIImage(systemName: "arrow.up.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor))) { [weak self] _ in self?.promoteSongs() }
	private lazy var aDemoteSong = UIAction(title: InterfaceText.moveDown, image: UIImage(systemName: "arrow.down.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor))) { [weak self] _ in self?.demoteSongs() }
	private lazy var aFloatSong = UIAction(title: InterfaceText.toTop, image: UIImage(systemName: "arrow.up.to.line")) { [weak self] _ in self?.floatSongs() }
	private lazy var aSinkSong = UIAction(title: InterfaceText.toBottom, image: UIImage(systemName: "arrow.down.to.line")) { [weak self] _ in self?.sinkSongs() }
	
	// MARK: - Focused
	
	private func titleFocused() -> String {
		switch albumListState.selectMode {
			case .selectAlbums(let idsSelected):
				return InterfaceText.NUMBER_albumsSelected(albumListState.albums(with: idsSelected).count)
			case .selectSongs(let idsSelected):
				return InterfaceText.NUMBER_songsSelected(albumListState.songs(with: idsSelected).count)
			case .view:
				switch albumListState.expansion {
					case .collapsed:
						return InterfaceText.NUMBER_albums(albumListState.albums().count)
					case .expanded:
						return InterfaceText.NUMBER_songs(albumListState.songs().count)
				}
		}
	}
	
	private func menuFocused() -> UIMenu {
		return UIMenu(options: .displayInline, children: [
			UIDeferredMenuElement.uncached { [weak self] use in
				guard let self else { return }
				let idsSongs = idsSongsFocused()
				let action = UIAction(title: InterfaceText.play, image: UIImage(systemName: "play")) { [weak self] _ in
					guard let self else { return }
					ApplicationMusicPlayer._shared?.playNow(idsSongs)
					endSelecting_animated()
				}
				if idsSongs.isEmpty { action.attributes.formUnion(.disabled) }
				use([action])
			},
			UIDeferredMenuElement.uncached { [weak self] use in
				guard let self else { return }
				let idsSongs = idsSongsFocused()
				let action = UIAction(title: InterfaceText.shuffle, image: UIImage(systemName: "shuffle")) { [weak self] _ in
					guard let self else { return }
					ApplicationMusicPlayer._shared?.playNow(idsSongs.shuffled()) // Don’t trust `MusicPlayer.shuffleMode`. As of iOS 17.6 developer beta 3, if you happen to set the queue with the same contents, and set `shuffleMode = .songs` after calling `play`, not before, then the same song always plays the first time. Instead of continuing to test and comment about this ridiculous API, I’d rather shuffle the songs myself and turn off Apple Music’s shuffle mode.
					endSelecting_animated()
				}
				if idsSongs.count <= 1 { action.attributes.formUnion(.disabled) }
				use([action])
			},
			UIDeferredMenuElement.uncached { [weak self] use in
				guard let self else { return }
				let idsSongs = idsSongsFocused()
				let action = UIAction(title: InterfaceText.addToQueue, image: UIImage(systemName: "text.line.last.and.arrowtriangle.forward")) { [weak self] _ in
					guard let self else { return }
					ApplicationMusicPlayer._shared?.playLater(idsSongs)
					endSelecting_animated()
				}
				if idsSongs.isEmpty { action.attributes.formUnion(.disabled) }
				use([action])
			},
		])
	}
	
	private func idsSongsFocused() -> [SongID] {
		switch albumListState.selectMode {
			case .selectAlbums(let idsSelected):
				return albumListState.albums(with: idsSelected).flatMap { $0.songs(sorted: true) }.map { $0.persistentID }
			case .selectSongs(let idsSelected):
				return albumListState.songs(with: idsSelected).map { $0.persistentID }
			case .view:
				switch albumListState.expansion {
					case .collapsed:
						return albumListState.albums().flatMap { $0.songs(sorted: true) }.map { $0.persistentID }
					case .expanded:
						return albumListState.songs().map { $0.persistentID }
				}
		}
	}
	
	// MARK: - Sorting
	
	private func menuSortAlbums() -> UIMenu {
		let groups: [[AlbumOrder]] = [[.recentlyAdded, .recentlyReleased], [.random, .reverse]]
		let menuSections: [UIMenu] = groups.map { albumOrders in
			UIMenu(options: .displayInline, children: albumOrders.map { order in
				UIDeferredMenuElement.uncached { [weak self] useElements in
					// Runs each time the button presents the menu
					guard let self else { return }
					let action = order.action { [weak self] in self?.sortAlbums(by: order) }
					if !canSortAlbums(by: order) { action.attributes.formUnion(.disabled) } // You must do this inside `UIDeferredMenuElement.uncached`.
					useElements([action])
				}
			})
		}
		return UIMenu(title: titleFocused(), children: menuSections + [menuFocused()])
	}
	private func canSortAlbums(by albumOrder: AlbumOrder) -> Bool {
		guard albumsToSort().count >= 2 else { return false }
		switch albumListState.selectMode {
			case .selectSongs, .view: break
			case .selectAlbums(let idsSelected):
				let rsSelected = albumListState.albums().indices {
					idsSelected.contains($0.albumPersistentID)
				}
				guard rsSelected.ranges.count <= 1 else { return false }
		}
		switch albumOrder {
			case .random, .reverse, .recentlyAdded: return true
			case .recentlyReleased: return albumsToSort().contains {
				nil != Librarian.shared.mkSectionInfo(albumID: $0.albumPersistentID)?._releaseDate
			}
		}
	}
	private func menuSortSongs() -> UIMenu {
		let groups: [[SongOrder]] = [[.track], [.random, .reverse]]
		let menuSections: [UIMenu] = groups.map { songOrders in
			UIMenu(options: .displayInline, children: songOrders.map { order in
				UIDeferredMenuElement.uncached { [weak self] useElements in
					guard let self else { return }
					let action = order.action { [weak self] in self?.sortSongs(by: order) }
					var enabling = true
					if songsToSort().count <= 1 { enabling = false }
					switch albumListState.selectMode {
						case .selectAlbums, .view: break
						case .selectSongs(let idsSelected):
							let rsSelected = albumListState.songs().indices {
								idsSelected.contains($0.persistentID)
							}
							if rsSelected.ranges.count >= 2 { enabling = false }
					}
					if !enabling { action.attributes.formUnion(.disabled) }
					useElements([action])
				}
			})
		}
		return UIMenu(title: titleFocused(), children: menuSections + [menuFocused()])
	}
	
	private func sortAlbums(by albumOrder: AlbumOrder) {
		Task {
			albumOrder.reindex(albumsToSort())
			ZZZDatabase.viewContext.savePlease()
			albumListState.refreshItems()
			let _ = await applyIDsRows(albumListState.rowIdentifiers())
		}
	}
	private func sortSongs(by songOrder: SongOrder) {
		Task {
			songOrder.reindex(songsToSort())
			ZZZDatabase.viewContext.savePlease()
			albumListState.refreshItems()
			let _ = await applyIDsRows(albumListState.rowIdentifiers())
		}
	}
	
	private func albumsToSort() -> [ZZZAlbum] {
		switch albumListState.selectMode {
			case .selectSongs: return []
			case .view: return albumListState.albums()
			case .selectAlbums(let idsSelected): return albumListState.albums(with: idsSelected)
		}
	}
	private func songsToSort() -> [ZZZSong] {
		switch albumListState.selectMode {
			case .selectAlbums: return []
			case .view: return albumListState.songs()
			case .selectSongs(let idsSelected): return albumListState.songs(with: idsSelected)
		}
	}
	
	// MARK: - Moving up and down
	
	private func promoteAlbums() {
		Task {
			guard
				case let .selectAlbums(idsSelected) = albumListState.selectMode,
				let crate = ZZZDatabase.viewContext.fetchCollection()
			else { return }
			crate.promoteAlbums(with: idsSelected)
			
			albumListState.refreshItems()
			NotificationCenter.default.post(name: AlbumListState.selectionChanged, object: albumListState) // We didn’t change which albums were selected, but we made them contiguous, which should enable sorting.
			let _ = await applyIDsRows(albumListState.rowIdentifiers(), runningBeforeContinuation: {
				guard
					let rowTarget = self.albumListState.listItems.firstIndex(where: { switch $0 {
						case .song: return false
						case .album(let album): return idsSelected.contains(album.albumPersistentID)
					}})
				else { return }
				self.tableView.scrollToRow(at: IndexPath(row: rowTarget, section: 0), at: .middle, animated: true)
			})
		}
	}
	private func promoteSongs() {
		Task {
			guard
				case let .selectSongs(idsSelected) = albumListState.selectMode,
				case let .expanded(idExpanded) = albumListState.expansion,
				let album = albumListState.albums(with: [idExpanded]).first
			else { return }
			album.promoteSongs(with: idsSelected)
			
			albumListState.refreshItems()
			NotificationCenter.default.post(name: AlbumListState.selectionChanged, object: albumListState)
			let _ = await applyIDsRows(albumListState.rowIdentifiers(), runningBeforeContinuation: {
				guard
					let rowTarget = self.albumListState.listItems.firstIndex(where: { switch $0 {
						case .album: return false
						case .song(let song): return idsSelected.contains(song.persistentID)
					}})
				else { return }
				self.tableView.scrollToRow(at: IndexPath(row: rowTarget, section: 0), at: .middle, animated: true)
			})
		}
	}
	
	private func demoteAlbums() {
		Task {
			guard
				case let .selectAlbums(idsSelected) = albumListState.selectMode,
				let crate = ZZZDatabase.viewContext.fetchCollection()
			else { return }
			crate.demoteAlbums(with: idsSelected)
			
			albumListState.refreshItems()
			NotificationCenter.default.post(name: AlbumListState.selectionChanged, object: albumListState)
			let _ = await applyIDsRows(albumListState.rowIdentifiers(), runningBeforeContinuation: {
				guard
					let rowTarget = self.albumListState.listItems.lastIndex(where: { switch $0 {
						case .song: return false
						case .album(let album): return idsSelected.contains(album.albumPersistentID)
					}})
				else { return }
				self.tableView.scrollToRow(at: IndexPath(row: rowTarget, section: 0), at: .middle, animated: true)
			})
		}
	}
	private func demoteSongs() {
		Task {
			guard
				case let .selectSongs(idsSelected) = albumListState.selectMode,
				case let .expanded(idExpanded) = albumListState.expansion,
				let album = albumListState.albums(with: [idExpanded]).first
			else { return }
			album.demoteSongs(with: idsSelected)
			
			albumListState.refreshItems()
			NotificationCenter.default.post(name: AlbumListState.selectionChanged, object: albumListState)
			let _ = await applyIDsRows(albumListState.rowIdentifiers(), runningBeforeContinuation: {
				guard
					let rowTarget = self.albumListState.listItems.lastIndex(where: { switch $0 {
						case .album: return false
						case .song(let song): return idsSelected.contains(song.persistentID)
					}})
				else { return }
				self.tableView.scrollToRow(at: IndexPath(row: rowTarget, section: 0), at: .middle, animated: true)
			})
		}
	}
	
	// MARK: To top and bottom
	
	private func floatAlbums() {
		Task {
			guard
				case let .selectAlbums(idsSelected) = albumListState.selectMode,
				let crate = ZZZDatabase.viewContext.fetchCollection()
			else { return }
			crate.floatAlbums(with: idsSelected)
			
			albumListState.refreshItems()
			albumListState.selectMode = .selectAlbums([])
			let _ = await applyIDsRows(albumListState.rowIdentifiers())
		}
	}
	private func floatSongs() {
		Task {
			guard
				case let .selectSongs(idsSelected) = albumListState.selectMode,
				case let .expanded(idExpanded) = albumListState.expansion,
				let album = albumListState.albums(with: [idExpanded]).first
			else { return }
			album.floatSongs(with: idsSelected)
			
			albumListState.refreshItems()
			albumListState.selectMode = .selectSongs([])
			let _ = await applyIDsRows(albumListState.rowIdentifiers())
		}
	}
	
	private func sinkAlbums() {
		Task {
			guard
				case let .selectAlbums(idsSelected) = albumListState.selectMode,
				let crate = ZZZDatabase.viewContext.fetchCollection()
			else { return }
			crate.sinkAlbums(with: idsSelected)
			
			albumListState.refreshItems()
			albumListState.selectMode = .selectAlbums([])
			let _ = await applyIDsRows(albumListState.rowIdentifiers())
		}
	}
	private func sinkSongs() {
		Task {
			guard
				case let .selectSongs(idsSelected) = albumListState.selectMode,
				case let .expanded(idExpanded) = albumListState.expansion,
				let album = albumListState.albums(with: [idExpanded]).first
			else { return }
			album.sinkSongs(with: idsSelected)
			
			albumListState.refreshItems()
			albumListState.selectMode = .selectSongs([])
			let _ = await applyIDsRows(albumListState.rowIdentifiers())
		}
	}
}
