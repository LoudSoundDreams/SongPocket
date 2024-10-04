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
				case .expanded(let expandedAlbumID):
					// If we removed the expanded album, go to collapsed mode.
					guard let iExpandedAlbum = albums.firstIndex(where: { album in
						expandedAlbumID == album.albumPersistentID
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
			case .view(let activatedID):
				if let activatedID, songs(with: [activatedID]).isEmpty {
					selectMode = .view(nil)
				}
			case .selectAlbums(let selectedIDs):
				guard !albums().isEmpty else {
					selectMode = .view(nil)
					break
				}
				let selectable: Set<AlbumID> = Set(
					albums(with: selectedIDs).map { $0.albumPersistentID }
				)
				if selectedIDs != selectable {
					selectMode = .selectAlbums(selectable)
				}
			case .selectSongs(let selectedIDs):
				guard !songs().isEmpty else {
					selectMode = .view(nil)
					break
				}
				let selectable: Set<SongID> = Set(
					songs(with: selectedIDs).map { $0.persistentID }
				)
				if selectedIDs != selectable{
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
		refreshBeginSelectingButton()
		bEllipsis.preferredMenuElementOrder = .fixed
		bEllipsis.menu = newAlbumSortMenu()
		
		NotificationCenter.default.addObserverOnce(self, selector: #selector(refreshBeginSelectingButton), name: Librarian.willMerge, object: nil)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(refreshLibraryItems), name: Librarian.didMerge, object: nil)
		Remote.shared.albumsTVC = WeakRef(self)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(reflectExpansion), name: AlbumListState.expansionChanged, object: albumListState)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(confirmPlay), name: SongRow.confirmPlaySongID, object: nil)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(reflectSelection), name: AlbumListState.selectionChanged, object: albumListState)
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
			onscreenRowIdentifiers = albumListState.rowIdentifiers()
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
					AlbumRow(albumID: rowAlbum.albumPersistentID, albumListState: albumListState)
				}.margins(.all, .zero)
				return cell
			case .song(let rowSong):
				switch albumListState.expansion {
					case .collapsed: return UITableViewCell() // Should never run
					case .expanded(let expandedAlbumID):
						// The cell in the storyboard is completely default except for the reuse identifier.
						let cell = tableView.dequeueReusableCell(withIdentifier: "Inline Song", for: indexPath)
						cell.backgroundColor = .clear
						cell.selectedBackgroundView = {
							let result = UIView()
							result.backgroundColor = .tintColor.withAlphaComponent(.oneHalf)
							return result
						}()
						cell.contentConfiguration = UIHostingConfiguration {
							SongRow(songID: rowSong.persistentID, albumID: expandedAlbumID, albumListState: albumListState)
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
			refreshBeginSelectingButton()
			switch albumListState.expansion {
				case .collapsed: bEllipsis.menu = newAlbumSortMenu()
				case .expanded: bEllipsis.menu = newSongSortMenu()
			}
			guard await applyRowIdentifiers(albumListState.rowIdentifiers()) else { return }
		}
	}
	
	func showCurrent() {
		guard
			let currentSongID = MPMusicPlayerController.nowPlayingID,
			let currentSong = ZZZDatabase.viewContext.fetchSong(mpID: currentSongID),
			let currentAlbumID = currentSong.container?.albumPersistentID
		else { return }
		guard let currentAlbumRow = albumListState.listItems.firstIndex(where: { switch $0 {
			case .song: return false
			case .album(let album): return currentAlbumID == album.albumPersistentID
		}}) else { return }
		tableView.performBatchUpdates {
			tableView.scrollToRow(at: IndexPath(row: currentAlbumRow, section: 0), at: .top, animated: true)
		} completion: { _ in
			self.albumListState.expansion = .expanded(currentAlbumID)
		}
	}
	
	@objc private func reflectExpansion() {
		switch albumListState.expansion {
			case .collapsed:
				Task {
					albumListState.refreshItems() // Immediately proceed to update the table view; don’t wait until a separate `Task`. As of iOS 17.6 developer beta 2, `UITableView` has a bug where it might call `cellForRowAt` with invalidly large `IndexPath`s: it’s trying to draw subsequent rows after we change a cell’s height in a `UIHostingConfiguration`, but forgetting to call `numberOfRowsInSection` first.
					bEllipsis.menu = newAlbumSortMenu()
					let _ = await applyRowIdentifiers(albumListState.rowIdentifiers())
				}
			case .expanded(let idToExpand):
				Task {
					guard albumListState.albums().contains(where: { idToExpand == $0.albumPersistentID }) else { return }
					albumListState.refreshItems()
					bEllipsis.menu = newSongSortMenu()
					let _ = await applyRowIdentifiers(albumListState.rowIdentifiers(), runningBeforeContinuation: {
						let expandingRow: Int = self.albumListState.listItems.firstIndex(where: { switch $0 {
							case .song: return false
							case .album(let album): return idToExpand == album.albumPersistentID
						}})!
						self.tableView.scrollToRow(at: IndexPath(row: expandingRow, section: 0), at: .top, animated: true)
					})
				}
		}
	}
	
	@objc private func reflectSelection() {
		switch albumListState.selectMode {
			case .view(let activatedID):
				setToolbarItems([beginSelectingButton, .flexibleSpace(), Remote.shared.bRemote, .flexibleSpace(), bEllipsis], animated: true)
				switch albumListState.expansion {
					case .collapsed: bEllipsis.menu = newAlbumSortMenu()
					case .expanded: bEllipsis.menu = newSongSortMenu()
				}
				if activatedID == nil {
					dismiss(animated: true) // In case “confirm play” action sheet is presented.
				}
			case .selectAlbums(let selectedIDs):
				setToolbarItems([endSelectingButton, .flexibleSpace(), bAlbumUp, .flexibleSpace(), bAlbumDown, .flexibleSpace(), bEllipsis], animated: true)
				bEllipsis.menu = newAlbumSortMenu() // In case it’s open.
				bAlbumUp.isEnabled = !selectedIDs.isEmpty
				bAlbumDown.isEnabled = bAlbumUp.isEnabled
			case .selectSongs(let selectedIDs):
				setToolbarItems([endSelectingButton, .flexibleSpace(), bSongUp, .flexibleSpace(), bSongDown, .flexibleSpace(), bEllipsis], animated: true)
				bEllipsis.menu = newSongSortMenu()
				bSongUp.isEnabled = !selectedIDs.isEmpty
				bSongDown.isEnabled = bSongUp.isEnabled
		}
	}
	
	@objc private func confirmPlay(notification: Notification) {
		guard
			let chosenSongID = notification.object as? SongID,
			let popoverSource: UIView = { () -> UIView? in
				guard let chosenRow = albumListState.listItems.firstIndex(where: { switch $0 {
					case .album: return false
					case .song(let song): return chosenSongID == song.persistentID
				}}) else { return nil }
				return tableView.cellForRow(at: IndexPath(row: chosenRow, section: 0))
			}()
		else { return }
		
		albumListState.selectMode = .view(chosenSongID) // The UI is clearer if we leave the row selected while the action sheet is onscreen. You must eventually deselect the row in every possible scenario after this moment.
		
		let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		actionSheet.popoverPresentationController?.sourceView = popoverSource
		actionSheet.addAction(
			UIAlertAction(title: InterfaceText.startPlaying, style: .default) { _ in
				Task {
					self.albumListState.selectMode = .view(nil)
					
					guard
						let chosenSong = self.albumListState.songs(with: [chosenSongID]).first,
						let chosenAlbum = chosenSong.container
					else { return }
					
					ApplicationMusicPlayer._shared?.playNow(
						chosenAlbum.songs(sorted: true).map { $0.persistentID },
						startingAt: chosenSong.persistentID)
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
	
	private lazy var beginSelectingButton = UIBarButtonItem(primaryAction: UIAction(title: InterfaceText.select, image: UIImage(systemName: "checkmark.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor))) { [weak self] _ in
		guard let self else { return }
		switch albumListState.expansion {
			case .collapsed:
				withAnimation {
					self.albumListState.selectMode = .selectAlbums([])
				}
			case .expanded:
				albumListState.selectMode = .selectSongs([])
		}
	})
	@objc private func refreshBeginSelectingButton() {
		beginSelectingButton.isEnabled = !albumListState.listItems.isEmpty && !Librarian.shared.isMerging
	}
	
	private lazy var endSelectingButton = UIBarButtonItem(primaryAction: UIAction(title: InterfaceText.done, image: UIImage(systemName: "checkmark.circle.fill")) { [weak self] _ in self?.endSelecting() })
	private func endSelecting() {
		switch albumListState.selectMode {
			case .view: break
			case .selectAlbums:
				withAnimation {
					self.albumListState.selectMode = .view(nil)
				}
			case .selectSongs:
				albumListState.selectMode = .view(nil)
		}
	}
	
	private let bEllipsis = UIBarButtonItem(title: InterfaceText.more, image: UIImage(systemName: "ellipsis.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor)))
	
	private lazy var bAlbumUp = UIBarButtonItem(primaryAction: aAlbumPromote, menu: UIMenu(children: [aAlbumFloat]))
	private lazy var bAlbumDown = UIBarButtonItem(primaryAction: aAlbumDemote, menu: UIMenu(children: [aAlbumSink]))
	
	private lazy var aAlbumPromote = UIAction(title: InterfaceText.moveUp, image: UIImage(systemName: "arrow.up.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor))) { [weak self] _ in self?.album_promote() }
	private lazy var aAlbumDemote = UIAction(title: InterfaceText.moveDown, image: UIImage(systemName: "arrow.down.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor))) { [weak self] _ in self?.album_demote() }
	private lazy var aAlbumFloat = UIAction(title: InterfaceText.toTop, image: UIImage(systemName: "arrow.up.to.line")) { [weak self] _ in self?.album_float() }
	private lazy var aAlbumSink = UIAction(title: InterfaceText.toBottom, image: UIImage(systemName: "arrow.down.to.line")) { [weak self] _ in self?.album_sink() }
	
	private lazy var bSongUp = UIBarButtonItem(primaryAction: aSongPromote, menu: UIMenu(children: [aSongFloat]))
	private lazy var bSongDown = UIBarButtonItem(primaryAction: aSongDemote, menu: UIMenu(children: [aSongSink]))
	
	private lazy var aSongPromote = UIAction(title: InterfaceText.moveUp, image: UIImage(systemName: "arrow.up.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor))) { [weak self] _ in self?.song_promote() }
	private lazy var aSongDemote = UIAction(title: InterfaceText.moveDown, image: UIImage(systemName: "arrow.down.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor))) { [weak self] _ in self?.song_demote() }
	private lazy var aSongFloat = UIAction(title: InterfaceText.toTop, image: UIImage(systemName: "arrow.up.to.line")) { [weak self] _ in self?.song_float() }
	private lazy var aSongSink = UIAction(title: InterfaceText.toBottom, image: UIImage(systemName: "arrow.down.to.line")) { [weak self] _ in self?.song_sink() }
	
	// MARK: - Focused
	
	private func newTitleFocused() -> String {
		switch albumListState.selectMode {
			case .selectAlbums(let selectedIDs):
				return InterfaceText.NUMBER_albums_selected(albumListState.albums(with: selectedIDs).count)
			case .selectSongs(let selectedIDs):
				return InterfaceText.NUMBER_songs_selected(albumListState.songs(with: selectedIDs).count)
			case .view:
				switch albumListState.expansion {
					case .collapsed:
						return InterfaceText.NUMBER_albums(albumListState.albums().count)
					case .expanded:
						return InterfaceText.NUMBER_songs(albumListState.songs().count)
				}
		}
	}
	
	private func newMenuFocused() -> UIMenu {
		return UIMenu(options: .displayInline, children: [
			UIDeferredMenuElement.uncached { [weak self] use in
				guard let self else { return }
				let idsSongs = idsSongsFocused()
				let action = UIAction(title: InterfaceText.play, image: UIImage(systemName: "play")) { [weak self] _ in
					guard let self else { return }
					ApplicationMusicPlayer._shared?.playNow(idsSongs)
					endSelecting()
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
					endSelecting()
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
					endSelecting()
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
	
	private func newAlbumSortMenu() -> UIMenu {
		let groups: [[AlbumOrder]] = [[.recentlyAdded, .recentlyReleased], [.random, .reverse]]
		let menuSections: [UIMenu] = groups.map { albumOrders in
			UIMenu(options: .displayInline, children: albumOrders.map { order in
				UIDeferredMenuElement.uncached { [weak self] useElements in
					// Runs each time the button presents the menu
					guard let self else { return }
					let action = order.newUIAction { [weak self] in self?.album_arrange(by: order) }
					if !album_allowsArrange(by: order) { action.attributes.formUnion(.disabled) } // You must do this inside `UIDeferredMenuElement.uncached`. `UIMenu` caches `UIAction.attributes`.
					useElements([action])
				}
			})
		}
		return UIMenu(title: newTitleFocused(), children: menuSections + [newMenuFocused()])
	}
	private func album_allowsArrange(by albumOrder: AlbumOrder) -> Bool {
		guard album_toArrange().count >= 2 else { return false }
		switch albumListState.selectMode {
			case .selectSongs, .view: break
			case .selectAlbums(let selectedIDs):
				let rsSelected = albumListState.albums().indices {
					selectedIDs.contains($0.albumPersistentID)
				}
				guard rsSelected.ranges.count <= 1 else { return false }
		}
		switch albumOrder {
			case .random, .reverse, .recentlyAdded: return true
			case .recentlyReleased: return album_toArrange().contains {
				nil != Librarian.shared.mkSectionInfo(albumID: $0.albumPersistentID)?._releaseDate
			}
		}
	}
	private func newSongSortMenu() -> UIMenu {
		let groups: [[SongOrder]] = [[.track], [.random, .reverse]]
		let menuSections: [UIMenu] = groups.map { songOrders in
			UIMenu(options: .displayInline, children: songOrders.map { order in
				UIDeferredMenuElement.uncached { [weak self] useElements in
					guard let self else { return }
					let action = order.newUIAction { [weak self] in self?.song_arrange(by: order) }
					var enabling = true
					if song_toArrange().count <= 1 { enabling = false }
					switch albumListState.selectMode {
						case .selectAlbums, .view: break
						case .selectSongs(let selectedIDs):
							let rsSelected = albumListState.songs().indices {
								selectedIDs.contains($0.persistentID)
							}
							if rsSelected.ranges.count >= 2 { enabling = false }
					}
					if !enabling { action.attributes.formUnion(.disabled) }
					useElements([action])
				}
			})
		}
		return UIMenu(title: newTitleFocused(), children: menuSections + [newMenuFocused()])
	}
	
	private func album_arrange(by albumOrder: AlbumOrder) {
		Task {
			albumOrder.reindex(album_toArrange())
			ZZZDatabase.viewContext.savePlease()
			albumListState.refreshItems()
			let _ = await applyRowIdentifiers(albumListState.rowIdentifiers())
		}
	}
	private func song_arrange(by songOrder: SongOrder) {
		Task {
			songOrder.reindex(song_toArrange())
			ZZZDatabase.viewContext.savePlease()
			albumListState.refreshItems()
			let _ = await applyRowIdentifiers(albumListState.rowIdentifiers())
		}
	}
	
	private func album_toArrange() -> [ZZZAlbum] {
		switch albumListState.selectMode {
			case .selectSongs: return []
			case .view:
				return albumListState.albums()
			case .selectAlbums(let selectedIDs):
				return albumListState.albums(with: selectedIDs)
		}
	}
	private func song_toArrange() -> [ZZZSong] {
		switch albumListState.selectMode {
			case .selectAlbums: return []
			case .view:
				return albumListState.songs()
			case .selectSongs(let selectedIDs):
				return albumListState.songs(with: selectedIDs)
		}
	}
	
	// MARK: - Moving up and down
	
	private func album_promote() {
		Task {
			guard
				case let .selectAlbums(idsSelected) = albumListState.selectMode,
				let crate = ZZZDatabase.viewContext.fetchCollection()
			else { return }
			crate.promoteAlbums(with: idsSelected)
			
			albumListState.refreshItems()
			NotificationCenter.default.post(name: AlbumListState.selectionChanged, object: albumListState) // We didn’t change which albums were selected, but we made them contiguous, which should enable sorting.
			let _ = await applyRowIdentifiers(albumListState.rowIdentifiers(), runningBeforeContinuation: {
				guard
					let targetRow = self.albumListState.listItems.firstIndex(where: { switch $0 {
						case .song: return false
						case .album(let album): return idsSelected.contains(album.albumPersistentID)
					}})
				else { return }
				self.tableView.scrollToRow(at: IndexPath(row: targetRow, section: 0), at: .middle, animated: true)
			})
		}
	}
	private func song_promote() {
		Task {
			guard
				case let .selectSongs(idsSelected) = albumListState.selectMode,
				case let .expanded(idExpanded) = albumListState.expansion,
				let album = albumListState.albums(with: [idExpanded]).first
			else { return }
			album.promoteSongs(with: idsSelected)
			
			albumListState.refreshItems()
			NotificationCenter.default.post(name: AlbumListState.selectionChanged, object: albumListState)
			let _ = await applyRowIdentifiers(albumListState.rowIdentifiers(), runningBeforeContinuation: {
				guard
					let targetRow = self.albumListState.listItems.firstIndex(where: { switch $0 {
						case .album: return false
						case .song(let song): return idsSelected.contains(song.persistentID)
					}})
				else { return }
				self.tableView.scrollToRow(at: IndexPath(row: targetRow, section: 0), at: .middle, animated: true)
			})
		}
	}
	
	private func album_demote() {
		Task {
			guard
				case let .selectAlbums(idsSelected) = albumListState.selectMode,
				let crate = ZZZDatabase.viewContext.fetchCollection()
			else { return }
			crate.demoteAlbums(with: idsSelected)
			
			albumListState.refreshItems()
			NotificationCenter.default.post(name: AlbumListState.selectionChanged, object: albumListState)
			let _ = await applyRowIdentifiers(albumListState.rowIdentifiers(), runningBeforeContinuation: {
				guard
					let targetRow = self.albumListState.listItems.lastIndex(where: { switch $0 {
						case .song: return false
						case .album(let album): return idsSelected.contains(album.albumPersistentID)
					}})
				else { return }
				self.tableView.scrollToRow(at: IndexPath(row: targetRow, section: 0), at: .middle, animated: true)
			})
		}
	}
	private func song_demote() {
		Task {
			guard
				case let .selectSongs(idsSelected) = albumListState.selectMode,
				case let .expanded(idExpanded) = albumListState.expansion,
				let album = albumListState.albums(with: [idExpanded]).first
			else { return }
			album.demoteSongs(with: idsSelected)
			
			albumListState.refreshItems()
			NotificationCenter.default.post(name: AlbumListState.selectionChanged, object: albumListState)
			let _ = await applyRowIdentifiers(albumListState.rowIdentifiers(), runningBeforeContinuation: {
				guard
					let targetRow = self.albumListState.listItems.lastIndex(where: { switch $0 {
						case .album: return false
						case .song(let song): return idsSelected.contains(song.persistentID)
					}})
				else { return }
				self.tableView.scrollToRow(at: IndexPath(row: targetRow, section: 0), at: .middle, animated: true)
			})
		}
	}
	
	// MARK: To top and bottom
	
	private func album_float() {
		Task {
			guard case let .selectAlbums(selectedIDs) = albumListState.selectMode else { return }
			let rsSelected = albumListState.albums().indices {
				selectedIDs.contains($0.albumPersistentID)
			}
			var inList = albumListState.albums()
			
			inList.moveSubranges(rsSelected, to: 0)
			ZZZDatabase.renumber(inList)
			
			ZZZDatabase.viewContext.savePlease()
			albumListState.refreshItems()
			albumListState.selectMode = .selectAlbums([])
			let _ = await applyRowIdentifiers(albumListState.rowIdentifiers())
		}
	}
	private func song_float() {
		Task {
			guard case let .selectSongs(selectedIDs) = albumListState.selectMode else { return }
			let rsSelected = albumListState.songs().indices {
				selectedIDs.contains($0.persistentID)
			}
			var inList = albumListState.songs()
			
			inList.moveSubranges(rsSelected, to: 0)
			ZZZDatabase.renumber(inList)
			
			ZZZDatabase.viewContext.savePlease()
			albumListState.refreshItems()
			albumListState.selectMode = .selectSongs([])
			let _ = await applyRowIdentifiers(albumListState.rowIdentifiers())
		}
	}
	
	private func album_sink() {
		Task {
			guard case let .selectAlbums(selectedIDs) = albumListState.selectMode else { return }
			let rsSelected = albumListState.albums().indices {
				selectedIDs.contains($0.albumPersistentID)
			}
			var inList = albumListState.albums()
			
			inList.moveSubranges(rsSelected, to: inList.count)
			ZZZDatabase.renumber(inList)
			
			ZZZDatabase.viewContext.savePlease()
			albumListState.refreshItems()
			albumListState.selectMode = .selectAlbums([])
			let _ = await applyRowIdentifiers(albumListState.rowIdentifiers())
		}
	}
	private func song_sink() {
		Task {
			guard case let .selectSongs(selectedIDs) = albumListState.selectMode else { return }
			let rsSelected = albumListState.songs().indices {
				selectedIDs.contains($0.persistentID)
			}
			var inList = albumListState.songs()
			
			inList.moveSubranges(rsSelected, to: inList.count)
			ZZZDatabase.renumber(inList)
			
			ZZZDatabase.viewContext.savePlease()
			albumListState.refreshItems()
			albumListState.selectMode = .selectSongs([])
			let _ = await applyRowIdentifiers(albumListState.rowIdentifiers())
		}
	}
}
