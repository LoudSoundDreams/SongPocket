// 2020-04-28

import UIKit
import SwiftUI
import MusicKit
import MediaPlayer

@MainActor @Observable final class AlbumListState {
	@ObservationIgnored fileprivate var listItems: [Item] = AlbumListState.freshAlbums().map { .album($0) }
	var expansion: Expansion = .collapsed
	var selectMode: SelectMode = .view(nil) { didSet {
		switch selectMode {
			case .view: break
			case .selectAlbums: NotificationCenter.default.post(name: Self.albumSelecting, object: self)
			case .selectSongs: NotificationCenter.default.post(name: Self.songSelecting, object: self)
		}
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
				let selectable: Set<AlbumID> = Set(
					albums(with: selectedIDs).map { $0.albumPersistentID }
				)
				if selectedIDs != selectable {
					selectMode = .selectAlbums(selectable)
				}
			case .selectSongs(let selectedIDs):
				let selectable: Set<SongID> = Set(
					songs(with: selectedIDs).map { $0.persistentID }
				)
				if selectedIDs != selectable{
					selectMode = .selectSongs(selectable)
				}
		}
	}
	private static func freshAlbums() -> [ZZZAlbum] {
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
	
	enum Expansion {
		case collapsed
		case expanded(AlbumID)
	}
	
	enum SelectMode: Equatable {
		case view(SongID?)
		case selectAlbums(Set<AlbumID>)
		case selectSongs(Set<SongID>) // Should always be within the same album.
	}
	static let albumSelecting = Notification.Name("LRAlbumSelecting")
	static let songSelecting = Notification.Name("LRSongSelecting")
}

// MARK: - View controller

final class AlbumsTVC: LibraryTVC {
	private let albumListState = AlbumListState()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = UIColor(Color(white: .oneEighth))
		tableView.separatorStyle = .none
		endSelecting()
		refreshBeginSelectingButton()
		bAlbumSort.preferredMenuElementOrder = .fixed
		bAlbumSort.menu = newAlbumSortMenu()
		bSongSort.preferredMenuElementOrder = .fixed
		bSongSort.menu = newSongSortMenu()
		
		NotificationCenter.default.addObserverOnce(self, selector: #selector(refreshBeginSelectingButton), name: Librarian.willMerge, object: nil)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(refreshLibraryItems), name: Librarian.didMerge, object: nil)
		Remote.shared.albumsTVC = WeakRef(self)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(expandAlbumID), name: AlbumRow.expandAlbumID, object: nil)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(collapse), name: AlbumRow.collapse, object: nil)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(confirmPlay), name: SongRow.confirmPlaySongID, object: nil)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(album_reflectSelected), name: AlbumListState.albumSelecting, object: albumListState)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(song_reflectSelected), name: AlbumListState.songSelecting, object: albumListState)
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
		guard MusicAuthorization.currentStatus == .authorized else { return 0 }
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
			switch albumListState.selectMode {
				case .view(let activatedID):
					if activatedID == nil {
						dismiss(animated: true) // In case “confirm play” action sheet is presented.
					}
				case .selectAlbums:
					if albumListState.albums().isEmpty {
						endSelecting()
					}
				case .selectSongs:
					if albumListState.songs().isEmpty { // Also works if we removed all albums.
						endSelecting()
					}
			}
			refreshBeginSelectingButton()
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
			self.expandAndAlignTo(currentAlbumID)
		}
	}
	
	@objc private func expandAlbumID(notification: Notification) {
		guard let idToOpen = notification.object as? AlbumID else { return }
		expandAndAlignTo(idToOpen)
	}
	private func expandAndAlignTo(_ idToExpand: AlbumID) {
		Task {
			guard albumListState.albums().contains(where: { idToExpand == $0.albumPersistentID }) else { return } // Because `showCurrent` calls this method in a completion handler, we might have removed the `Album` by now.
			albumListState.expansion = .expanded(idToExpand)
			albumListState.refreshItems()
			let _ = await applyRowIdentifiers(albumListState.rowIdentifiers(), runningBeforeContinuation: {
				let expandingRow: Int = self.albumListState.listItems.firstIndex(where: { switch $0 {
					case .song: return false
					case .album(let album): return idToExpand == album.albumPersistentID
				}})!
				self.tableView.scrollToRow(at: IndexPath(row: expandingRow, section: 0), at: .top, animated: true)
			})
		}
	}
	@objc private func collapse() {
		Task {
			albumListState.expansion = .collapsed
			albumListState.refreshItems() // Immediately proceed to update the table view; don’t wait until a separate `Task`. As of iOS 17.6 developer beta 2, `UITableView` has a bug where it might call `cellForRowAt` with invalidly large `IndexPath`s: it’s trying to draw subsequent rows after we change a cell’s height in a `UIHostingConfiguration`, but forgetting to call `numberOfRowsInSection` first.
			let _ = await applyRowIdentifiers(albumListState.rowIdentifiers())
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
	
	@objc private func refreshBeginSelectingButton() {
		beginSelectingButton.isEnabled =
		!albumListState.listItems.isEmpty &&
		MusicAuthorization.currentStatus == .authorized && // If the user revokes access, we’re showing the placeholder, but the view model is probably non-empty.
		!Librarian.shared.isMerging
	}
	
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
	private lazy var endSelectingButton = UIBarButtonItem(primaryAction: UIAction(title: InterfaceText.done, image: UIImage(systemName: "checkmark.circle.fill")) { [weak self] _ in self?.endSelecting() })
	
	private func endSelecting() {
		if !WorkingOn.plainDatabase {
			ZZZDatabase.viewContext.savePlease()
		}
		
		switch albumListState.selectMode {
			case .view: break
			case .selectAlbums:
				withAnimation {
					albumListState.selectMode = .view(nil)
				}
			case .selectSongs:
				albumListState.selectMode = .view(nil)
		}
		setToolbarItems([beginSelectingButton, .flexibleSpace(), Remote.shared.playPauseButton, .flexibleSpace(), Remote.shared.overflowButton], animated: true)
	}
	
	private let bEllipsis = UIBarButtonItem(title: InterfaceText.more, image: UIImage(systemName: "ellipsis.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor)))
	
	private let bAlbumSort = UIBarButtonItem(title: InterfaceText.sort, image: UIImage(systemName: "arrow.up.arrow.down"))
	private lazy var bAlbumUp = UIBarButtonItem(primaryAction: aAlbumPromote, menu: UIMenu(children: [aAlbumFloat]))
	private lazy var bAlbumDown = UIBarButtonItem(primaryAction: aAlbumDemote, menu: UIMenu(children: [aAlbumSink]))
	
	private lazy var aAlbumPromote = UIAction(title: InterfaceText.moveUp, image: UIImage(systemName: "arrow.up")) { [weak self] _ in self?.album_promote() }
	private lazy var aAlbumDemote = UIAction(title: InterfaceText.moveDown, image: UIImage(systemName: "arrow.down")) { [weak self] _ in self?.album_demote() }
	private lazy var aAlbumFloat = UIAction(title: InterfaceText.toTop, image: UIImage(systemName: "arrow.up.to.line")) { [weak self] _ in self?.album_float() }
	private lazy var aAlbumSink = UIAction(title: InterfaceText.toBottom, image: UIImage(systemName: "arrow.down.to.line")) { [weak self] _ in self?.album_sink() }
	
	private let bSongSort = UIBarButtonItem(title: InterfaceText.sort, image: UIImage(systemName: "arrow.up.arrow.down"))
	private lazy var bSongUp = UIBarButtonItem(primaryAction: aSongPromote, menu: UIMenu(children: [aSongFloat]))
	private lazy var bSongDown = UIBarButtonItem(primaryAction: aSongDemote, menu: UIMenu(children: [aSongSink]))
	
	private lazy var aSongPromote = UIAction(title: InterfaceText.moveUp, image: UIImage(systemName: "arrow.up")) { [weak self] _ in self?.song_promote() }
	private lazy var aSongDemote = UIAction(title: InterfaceText.moveDown, image: UIImage(systemName: "arrow.down")) { [weak self] _ in self?.song_demote() }
	private lazy var aSongFloat = UIAction(title: InterfaceText.toTop, image: UIImage(systemName: "arrow.up.to.line")) { [weak self] _ in self?.song_float() }
	private lazy var aSongSink = UIAction(title: InterfaceText.toBottom, image: UIImage(systemName: "arrow.down.to.line")) { [weak self] _ in self?.song_sink() }
	
	@objc private func album_reflectSelected() {
		setToolbarItems([endSelectingButton, .flexibleSpace(), bAlbumSort, .flexibleSpace(), bAlbumUp, .flexibleSpace(), bAlbumDown], animated: true)
		
		bAlbumSort.isEnabled = { switch albumListState.selectMode {
			case .selectSongs: return false
			case .view: return true
			case .selectAlbums(let selectedIDs):
				if selectedIDs.isEmpty { return true }
				let selectedIndices: [Int] = albumListState.albums().indices__ {
					selectedIDs.contains($0.albumPersistentID)
				}
				return selectedIndices.isConsecutive()
		}}()
		bAlbumUp.isEnabled = { switch albumListState.selectMode {
			case .view, .selectSongs: return false
			case .selectAlbums(let selectedIDs): return !selectedIDs.isEmpty
		}}()
		bAlbumDown.isEnabled = bAlbumUp.isEnabled
	}
	@objc private func song_reflectSelected() {
		setToolbarItems([endSelectingButton, .flexibleSpace(), bSongSort, .flexibleSpace(), bSongUp, .flexibleSpace(), bSongDown], animated: true)
		
		bSongSort.isEnabled = { switch albumListState.selectMode {
			case .view, .selectAlbums: return false
			case .selectSongs(let selectedIDs):
				if selectedIDs.isEmpty { return true }
				let selectedIndices: [Int] = albumListState.songs().indices__ {
					selectedIDs.contains($0.persistentID)
				}
				return selectedIndices.isConsecutive()
		}}()
		bSongUp.isEnabled = { switch albumListState.selectMode {
			case .view, .selectAlbums: return false
			case .selectSongs(let selectedIDs): return !selectedIDs.isEmpty
		}}()
		bSongDown.isEnabled = bSongUp.isEnabled
	}
	
	// MARK: - Sorting
	
	private func newAlbumSortMenu() -> UIMenu {
		let groups: [[AlbumOrder]] = [[.recentlyAdded, .recentlyReleased, .artist, .title], [.random, .reverse]]
		let submenus: [UIMenu] = groups.map { group in
			UIMenu(options: .displayInline, children: group.map { albumOrder in
				UIDeferredMenuElement.uncached { [weak self] useElements in
					// Runs each time the button presents the menu
					guard let self else { return }
					let action = albumOrder.newUIAction { [weak self] in self?.album_arrange(by: albumOrder) }
					if !album_allowsArrange(by: albumOrder) { action.attributes.formUnion(.disabled) } // You must do this inside `UIDeferredMenuElement.uncached`. `UIMenu` caches `UIAction.attributes`.
					useElements([action])
				}
			})
		}
		return UIMenu(children: submenus)
	}
	private func album_allowsArrange(by albumOrder: AlbumOrder) -> Bool {
		guard album_toArrange().count >= 2 else { return false }
		switch albumOrder {
			case .random, .reverse, .recentlyAdded, .title, .artist: return true
			case .recentlyReleased: return album_toArrange().contains {
				nil != Librarian.shared.mkSectionInfo(albumID: $0.albumPersistentID)?._releaseDate
			}
		}
	}
	private func newSongSortMenu() -> UIMenu {
		let groups: [[SongOrder]] = [[.track], [.random, .reverse]]
		let submenus: [UIMenu] = groups.map { group in
			UIMenu(options: .displayInline, children: group.map { songOrder in
				UIDeferredMenuElement.uncached { [weak self] useElements in
					guard let self else { return }
					let action = songOrder.newUIAction { [weak self] in self?.song_arrange(by: songOrder) }
					if song_toArrange().count <= 1 { action.attributes.formUnion(.disabled) }
					useElements([action])
				}
			})
		}
		return UIMenu(children: submenus)
	}
	
	private func album_arrange(by albumOrder: AlbumOrder) {
		Task {
			albumOrder.reindex(album_toArrange())
			albumListState.refreshItems()
			let _ = await applyRowIdentifiers(albumListState.rowIdentifiers())
		}
	}
	private func song_arrange(by songOrder: SongOrder) {
		Task {
			songOrder.reindex(song_toArrange())
			albumListState.refreshItems()
			let _ = await applyRowIdentifiers(albumListState.rowIdentifiers())
		}
	}
	
	private func album_toArrange() -> [ZZZAlbum] {
		switch albumListState.selectMode {
			case .selectSongs: return []
			case .view: break
			case .selectAlbums(let selectedIDs):
				if selectedIDs.isEmpty { break }
				return albumListState.albums(with: selectedIDs)
		}
		return albumListState.albums()
	}
	private func song_toArrange() -> [ZZZSong] {
		switch albumListState.selectMode {
			case .selectAlbums: return []
			case .view: break
			case .selectSongs(let selectedIDs):
				if selectedIDs.isEmpty { break }
				return albumListState.songs(with: selectedIDs)
		}
		return albumListState.songs()
	}
	
	// MARK: - Moving up and down
	
	private func album_promote() {
		Task {
			guard case let .selectAlbums(selectedIDs) = albumListState.selectMode else { return }
			let selectedIndices: [Int64] = albumListState.albums().indices__ {
				selectedIDs.contains($0.albumPersistentID)
			}.map { Int64($0) }
			guard let front = selectedIndices.first, let back = selectedIndices.last else { return }
			
			let target: Int64 = selectedIndices.isConsecutive() ? max(front-1, 0) : front
			let range = (target...back)
			let inRange: [ZZZAlbum] = range.map { int64 in albumListState.albums()[Int(int64)] }
			let toPromote = inRange.filter { selectedIDs.contains($0.albumPersistentID) }
			let toDisplace = inRange.filter { !selectedIDs.contains($0.albumPersistentID) }
			let newBlock: [ZZZAlbum] = toPromote + toDisplace
			
			newBlock.indices.forEach { offset in
				newBlock[offset].index = target + Int64(offset)
			}
			albumListState.refreshItems()
			album_reflectSelected() // We didn’t change which albums were selected, but we made them contiguous, which should enable sorting.
			let _ = await applyRowIdentifiers(albumListState.rowIdentifiers(), runningBeforeContinuation: {
				self.tableView.scrollToRow(at: IndexPath(row: Int(target), section: 0), at: .middle, animated: true)
			})
		}
	}
	private func song_promote() {
		Task {
			guard case let .selectSongs(selectedIDs) = albumListState.selectMode else { return }
			let selectedIndices: [Int64] = albumListState.songs().indices__ {
				selectedIDs.contains($0.persistentID)
			}.map { Int64($0) }
			guard let front = selectedIndices.first, let back = selectedIndices.last else { return }
			
			let target: Int64 = selectedIndices.isConsecutive() ? max(front-1, 0) : front
			let range = (target...back)
			let inRange: [ZZZSong] = range.map { int64 in albumListState.songs()[Int(int64)] }
			let toPromote = inRange.filter { selectedIDs.contains($0.persistentID) }
			let toDisplace = inRange.filter { !selectedIDs.contains($0.persistentID) }
			let newBlock: [ZZZSong] = toPromote + toDisplace
			
			newBlock.indices.forEach { offset in
				newBlock[offset].index = target + Int64(offset)
			}
			albumListState.refreshItems()
			song_reflectSelected()
			let _ = await applyRowIdentifiers(albumListState.rowIdentifiers(), runningBeforeContinuation: {
				guard
					let frontSong = newBlock.first,
					let targetRow = self.albumListState.listItems.firstIndex(where: { switch $0 {
						case .album: return false
						case .song(let song): return frontSong.persistentID == song.persistentID
					}})
				else { return }
				self.tableView.scrollToRow(at: IndexPath(row: targetRow, section: 0), at: .middle, animated: true)
			})
		}
	}
	
	private func album_demote() {
		Task {
			guard case let .selectAlbums(selectedIDs) = albumListState.selectMode else { return }
			let selectedIndices: [Int64] = albumListState.albums().indices__ {
				selectedIDs.contains($0.albumPersistentID)
			}.map { Int64($0) }
			guard let front = selectedIndices.first, let back = selectedIndices.last else { return }
			
			let target: Int64 = selectedIndices.isConsecutive() ? min(back+1, Int64(albumListState.albums().count)-1) : back
			let range = (front...target)
			let inRange: [ZZZAlbum] = range.map { int64 in albumListState.albums()[Int(int64)] }
			let toDemote = inRange.filter { selectedIDs.contains($0.albumPersistentID) }
			let toDisplace = inRange.filter { !selectedIDs.contains($0.albumPersistentID) }
			let newBlock: [ZZZAlbum] = toDisplace + toDemote
			
			newBlock.indices.forEach { offset in
				newBlock[offset].index = front + Int64(offset)
			}
			albumListState.refreshItems()
			NotificationCenter.default.post(name: AlbumListState.albumSelecting, object: albumListState)
			let _ = await applyRowIdentifiers(albumListState.rowIdentifiers(), runningBeforeContinuation: {
				self.tableView.scrollToRow(at: IndexPath(row: Int(target), section: 0), at: .middle, animated: true)
			})
		}
	}
	private func song_demote() {
		Task {
			guard case let .selectSongs(selectedIDs) = albumListState.selectMode else { return }
			let selectedIndices: [Int64] = albumListState.songs().indices__ {
				selectedIDs.contains($0.persistentID)
			}.map { Int64($0) }
			guard let front = selectedIndices.first, let back = selectedIndices.last else { return }
			
			let target: Int64 = selectedIndices.isConsecutive() ? min(back+1, Int64(albumListState.songs().count)-1) : back
			let range = (front...target)
			let inRange: [ZZZSong] = range.map { int64 in albumListState.songs()[Int(int64)] }
			let toDemote = inRange.filter { selectedIDs.contains($0.persistentID) }
			let toDisplace = inRange.filter { !selectedIDs.contains($0.persistentID) }
			let newBlock: [ZZZSong] = toDisplace + toDemote
			
			newBlock.indices.forEach { offset in
				newBlock[offset].index = front + Int64(offset)
			}
			albumListState.refreshItems()
			NotificationCenter.default.post(name: AlbumListState.songSelecting, object: albumListState)
			let _ = await applyRowIdentifiers(albumListState.rowIdentifiers(), runningBeforeContinuation: {
				guard
					let backSong = newBlock.last,
					let targetRow = self.albumListState.listItems.firstIndex(where: { switch $0 {
						case .album: return false
						case .song(let song): return backSong.persistentID == song.persistentID
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
			let selectedIndices: [Int64] = albumListState.albums().indices__ {
				selectedIDs.contains($0.albumPersistentID)
			}.map { Int64($0) }
			guard let back = selectedIndices.last else { return }
			
			let range = (0...back)
			let inRange: [ZZZAlbum] = range.map { int64 in albumListState.albums()[Int(int64)] }
			let toFloat = inRange.filter { selectedIDs.contains($0.albumPersistentID) }
			let toDisplace = inRange.filter { !selectedIDs.contains($0.albumPersistentID) }
			let newBlock: [ZZZAlbum] = toFloat + toDisplace
			
			albumListState.selectMode = .selectAlbums([])
			newBlock.indices.forEach { offset in
				newBlock[offset].index = Int64(offset)
			}
			albumListState.refreshItems()
			let _ = await applyRowIdentifiers(albumListState.rowIdentifiers())
		}
	}
	private func song_float() {
		Task {
			guard case let .selectSongs(selectedIDs) = albumListState.selectMode else { return }
			let selectedIndices: [Int64] = albumListState.songs().indices__ {
				selectedIDs.contains($0.persistentID)
			}.map { Int64($0) }
			guard let back = selectedIndices.last else { return }
			
			let range = (0...back)
			let inRange: [ZZZSong] = range.map { int64 in albumListState.songs()[Int(int64)] }
			let toFloat = inRange.filter { selectedIDs.contains($0.persistentID) }
			let toDisplace = inRange.filter { !selectedIDs.contains($0.persistentID) }
			let newBlock: [ZZZSong] = toFloat + toDisplace
			
			albumListState.selectMode = .selectSongs([])
			newBlock.indices.forEach { offset in
				newBlock[offset].index = Int64(offset)
			}
			albumListState.refreshItems()
			let _ = await applyRowIdentifiers(albumListState.rowIdentifiers())
		}
	}
	
	private func album_sink() {
		Task {
			guard case let .selectAlbums(selectedIDs) = albumListState.selectMode else { return }
			let selectedIndices: [Int64] = albumListState.albums().indices__ {
				selectedIDs.contains($0.albumPersistentID)
			}.map { Int64($0) }
			guard let front = selectedIndices.first else { return }
			
			let range = (front...Int64(albumListState.albums().count)-1)
			let inRange: [ZZZAlbum] = range.map { int64 in albumListState.albums()[Int(int64)] }
			let toSink = inRange.filter { selectedIDs.contains($0.albumPersistentID) }
			let toDisplace = inRange.filter { !selectedIDs.contains($0.albumPersistentID) }
			let newBlock: [ZZZAlbum] = toDisplace + toSink
			
			albumListState.selectMode = .selectAlbums([])
			newBlock.indices.forEach { offset in
				newBlock[offset].index = front + Int64(offset)
			}
			albumListState.refreshItems()
			let _ = await applyRowIdentifiers(albumListState.rowIdentifiers())
		}
	}
	private func song_sink() {
		Task {
			guard case let .selectSongs(selectedIDs) = albumListState.selectMode else { return }
			let selectedIndices: [Int64] = albumListState.songs().indices__ {
				selectedIDs.contains($0.persistentID)
			}.map { Int64($0) }
			guard let front = selectedIndices.first else { return }
			
			let range = (front...(Int64(albumListState.songs().count)-1))
			let inRange: [ZZZSong] = range.map { int64 in albumListState.songs()[Int(int64)] }
			let toSink = inRange.filter { selectedIDs.contains($0.persistentID) }
			let toDisplace = inRange.filter { !selectedIDs.contains($0.persistentID) }
			let newBlock: [ZZZSong] = toDisplace + toSink
			
			albumListState.selectMode = .selectSongs([])
			newBlock.indices.forEach { offset in
				newBlock[offset].index = front + Int64(offset)
			}
			albumListState.refreshItems()
			let _ = await applyRowIdentifiers(albumListState.rowIdentifiers())
		}
	}
}
