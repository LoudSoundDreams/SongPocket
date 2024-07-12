// 2020-04-28

import UIKit
import SwiftUI
import MusicKit
import MediaPlayer
import CoreData

@MainActor @Observable final class AlbumListState {
	@ObservationIgnored fileprivate var items: [Item] = AlbumListState.freshAlbums().map { .album($0) } // Retain old items until we explicitly refresh them, so we can diff them for updating the table view.
	var viewportSize: (width: CGFloat, height: CGFloat) = (.zero, .zero)
	var expansion: Expansion = .collapsed
	var selectMode: SelectMode = .view(nil) { didSet {
		switch selectMode {
			case .view: break
			case .selectAlbums: NotificationCenter.default.post(name: Self.selectingAlbums, object: self)
			case .selectSongs: NotificationCenter.default.post(name: Self.selectingSongs, object: self)
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
	func albums(with chosenIDs: Set<AlbumID>? = nil) -> [Album] {
		return items.compactMap { switch $0 {
			case .song: return nil
			case .album(let album):
				guard let chosenIDs else { return album }
				guard chosenIDs.contains(album.albumPersistentID) else { return nil }
				return album
		}}
	}
	fileprivate func songs(with chosenIDs: Set<SongID>? = nil) -> [Song] {
		return items.compactMap { switch $0 {
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
	static let selectingAlbums = Notification.Name("LRSelectingAlbums")
	static let selectingSongs = Notification.Name("LRSelectingSongs")
}

// MARK: - Table view controller

final class AlbumsTVC: LibraryTVC {
	private let albumListState = AlbumListState()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = UIColor(Color(hue: 0, saturation: 0, brightness: .oneEighth))
		tableView.separatorStyle = .none
		endSelecting()
		refreshBeginSelectingButton()
		
		NotificationCenter.default.addObserverOnce(self, selector: #selector(refreshLibraryItems), name: MusicRepo.mergedChanges, object: nil)
		__MainToolbar.shared.albumsTVC = WeakRef(self)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(expandAlbumID), name: AlbumRow.expandAlbumID, object: nil)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(collapse), name: AlbumRow.collapse, object: nil)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(confirmPlay), name: SongRow.confirmPlaySongID, object: nil)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(album_reflectSelected), name: AlbumListState.selectingAlbums, object: albumListState)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(song_reflectSelected), name: AlbumListState.selectingSongs, object: albumListState)
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
						// The cell in the storyboard is completely default except for the reuse identifier.
						let cell = tableView.dequeueReusableCell(withIdentifier: "Inline Song", for: indexPath)
						cell.backgroundColor = .clear
						cell.selectedBackgroundView = {
							let result = UIView()
							result.backgroundColor = .tintColor.withAlphaComponent(.oneHalf)
							return result
						}()
						cell.contentConfiguration = UIHostingConfiguration {
							SongRow(song: rowSong, albumID: expandedAlbumID, albumListState: albumListState)
						}.margins(.all, .zero)
						return cell
				}
		}
	}
	private func cellForAlbum(cell: UITableViewCell, album: Album) -> UITableViewCell {
		cell.backgroundColor = .clear
		cell.selectedBackgroundView = {
			let result = UIView()
			result.backgroundColor = .tintColor.withAlphaComponent(.oneHalf)
			return result
		}()
		albumListState.viewportSize = (
			width: view.frame.width,
			height: view.frame.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom
		)
		cell.contentConfiguration = UIHostingConfiguration {
			AlbumRow(albumID: album.albumPersistentID, albumListState: albumListState)
		}.margins(.all, .zero)
		return cell
	}
	
	override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? { return nil }
	
	// MARK: - Events
	
	override func viewWillTransition(
		to size: CGSize,
		with coordinator: UIViewControllerTransitionCoordinator
	) {
		super.viewWillTransition(to: size, with: coordinator)
		albumListState.viewportSize = (
			width: size.width,
			height: size.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom
		)
	}
	
	@objc private func refreshLibraryItems() {
		Task {
			let oldRows = albumListState.rowIdentifiers()
			albumListState.refreshItems()
			refreshBeginSelectingButton()
			switch albumListState.selectMode { // In case the user was in the middle of doing something with an item we’ve deleted.
				case .view(let activatedID):
					var newActivated = activatedID
					if let activatedID, albumListState.songs(with: [activatedID]).isEmpty {
						dismiss(animated: true) // In case “confirm play” action sheet is presented.
						newActivated = nil
					}
					albumListState.selectMode = .view(newActivated)
				case .selectAlbums(let selectedIDs):
					let newSelected: Set<AlbumID> = Set(albumListState.albums(with: selectedIDs).map { $0.albumPersistentID })
					albumListState.selectMode = .selectAlbums(newSelected)
				case .selectSongs(let selectedIDs):
					let newSelected: Set<SongID> = Set(albumListState.songs(with: selectedIDs).map { $0.persistentID} )
					// TO DO: End selecting if we deleted the current album (and set `expansion = .collapsed`).
					albumListState.selectMode = .selectSongs(newSelected)
			}
			if albumListState.items.isEmpty {
				endSelecting()
			}
			guard await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers()) else { return }
			
			// Update the data within each row, which might be outdated.
			tableView.reconfigureRows(at: tableView.allIndexPaths())
		}
	}
	
	func showCurrent() {
		guard let uInt64 = MPMusicPlayerController._system?.nowPlayingItem?.albumPersistentID else { return }
		let currentAlbumID = AlbumID(bitPattern: uInt64)
		// The current song might not be in our database, but the current `Album` is.
		guard let currentAlbumRow = albumListState.items.firstIndex(where: { switch $0 {
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
			let oldRows = albumListState.rowIdentifiers()
			albumListState.expansion = .expanded(idToExpand)
			albumListState.refreshItems()
			let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers(), runningBeforeContinuation: {
				let expandingRow: Int = self.albumListState.items.firstIndex(where: { switch $0 {
					case .song: return false
					case .album(let album): return idToExpand == album.albumPersistentID
				}})!
				self.tableView.scrollToRow(at: IndexPath(row: expandingRow, section: 0), at: .top, animated: true)
			})
		}
	}
	@objc private func collapse() {
		Task {
			let oldRows = albumListState.rowIdentifiers()
			albumListState.expansion = .collapsed
			albumListState.refreshItems() // Immediately proceed to update the table view; don’t wait until a separate `Task`. As of iOS 17.6 developer beta 2, `UITableView` has a bug where it might call `cellForRowAt` with invalidly large `IndexPath`s: it’s trying to draw subsequent rows after we change a cell’s height in a `UIHostingConfiguration`, but forgetting to call `numberOfRowsInSection` first.
			let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers())
		}
	}
	
	@objc private func confirmPlay(notification: Notification) {
		guard
			let chosenSongID = notification.object as? SongID,
			let popoverSource: UIView = { () -> UIView? in
				guard let chosenRow = albumListState.items.firstIndex(where: { switch $0 {
					case .album: return false
					case .song(let song): return chosenSongID == song.persistentID
				}}) else { return nil }
				return tableView.cellForRow(at: IndexPath(row: chosenRow, section: 0))
			}(),
		presentedViewController == nil // As of iOS 17.6 developer beta 1, if a `UIMenu` or SwiftUI `Menu` is open, `present` does nothing.
		// We could call `dismiss` and wait until completion to `present`, but that would be a worse user experience, because tapping outside the menu to close it could open this action sheet. So it’s better to do nothing here and simply let the tap close the menu.
		// Technically this is inconsistent because we still select and deselect items and open albums when dismissing a menu; and because toolbar buttons do nothing when dismissing a menu. But at least this prevents the most annoying behavior.
		else { return }
		
		albumListState.selectMode = .view(chosenSongID) // The UI is clearer if we leave the row selected while the action sheet is onscreen. You must eventually deselect the row in every possible scenario after this moment.
		
		let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		actionSheet.popoverPresentationController?.sourceView = popoverSource
		actionSheet.addAction(
			UIAlertAction(title: InterfaceText.startPlaying, style: .default) { _ in
				Task {
					guard let chosenSong = self.albumListState.songs(with: [chosenSongID]).first else { return }
					await chosenSong.playAlbumStartingHere()
					
					self.albumListState.selectMode = .view(nil)
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
	
	private func refreshBeginSelectingButton() {
		beginSelectingButton.isEnabled = !albumListState.items.isEmpty && MusicAuthorization.currentStatus == .authorized // If the user revokes access, we’re showing the placeholder, but the view model is probably non-empty.
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
		Database.viewContext.savePlease()
		
		switch albumListState.selectMode {
			case .view: break
			case .selectAlbums:
				withAnimation {
					albumListState.selectMode = .view(nil)
				}
			case .selectSongs:
				albumListState.selectMode = .view(nil)
		}
		setToolbarItems([beginSelectingButton, .flexibleSpace(), __MainToolbar.shared.playPauseButton, .flexibleSpace(), __MainToolbar.shared.overflowButton], animated: true)
	}
	
	private let album_arranger = UIBarButtonItem(title: InterfaceText.sort, image: UIImage(systemName: "arrow.up.arrow.down"))
	private lazy var album_promoter = UIBarButtonItem(title: InterfaceText.moveUp, image: UIImage(systemName: "chevron.up"), primaryAction: UIAction { [weak self] _ in self?.album_promote() }, menu: UIMenu(children: [UIAction(title: InterfaceText.toTop, image: UIImage(systemName: "arrow.up.to.line")) { [weak self] _ in self?.album_float() }]))
	private lazy var album_demoter = UIBarButtonItem(title: InterfaceText.moveDown, image: UIImage(systemName: "chevron.down"), primaryAction: UIAction { [weak self] _ in self?.album_demote() }, menu: UIMenu(children: [UIAction(title: InterfaceText.toBottom, image: UIImage(systemName: "arrow.down.to.line")) { [weak self] _ in self?.album_sink() }]))
	
	private let song_arranger = UIBarButtonItem(title: InterfaceText.sort, image: UIImage(systemName: "arrow.up.arrow.down"))
	private lazy var song_promoter = UIBarButtonItem(title: InterfaceText.moveUp, image: UIImage(systemName: "chevron.up"), primaryAction: UIAction { [weak self] _ in self?.song_promote() }, menu: UIMenu(children: [UIAction(title: InterfaceText.toTop, image: UIImage(systemName: "arrow.up.to.line")) { [weak self] _ in self?.song_float() }]))
	private lazy var song_demoter = UIBarButtonItem(title: InterfaceText.moveDown, image: UIImage(systemName: "chevron.down"), primaryAction: UIAction { [weak self] _ in self?.song_demote() }, menu: UIMenu(children: [UIAction(title: InterfaceText.toBottom, image: UIImage(systemName: "arrow.down.to.line")) { [weak self] _ in self?.song_sink() }]))
	
	@objc private func album_reflectSelected() {
		setToolbarItems([endSelectingButton, .flexibleSpace(), album_arranger, .flexibleSpace(), album_promoter, .flexibleSpace(), album_demoter], animated: true)
		
		album_arranger.isEnabled = { switch albumListState.selectMode {
			case .selectSongs: return false
			case .view: return true
			case .selectAlbums(let selectedIDs):
				if selectedIDs.isEmpty { return true }
				let selectedIndices: [Int64] = albumListState.albums(with: selectedIDs).map { $0.index }
				return selectedIndices.isConsecutive()
		}}()
		album_refreshArrangeMenu()
		album_promoter.isEnabled = { switch albumListState.selectMode {
			case .view, .selectSongs: return false
			case .selectAlbums(let selectedIDs): return !selectedIDs.isEmpty
		}}()
		album_demoter.isEnabled = album_promoter.isEnabled
	}
	@objc private func song_reflectSelected() {
		setToolbarItems([endSelectingButton, .flexibleSpace(), song_arranger, .flexibleSpace(), song_promoter, .flexibleSpace(), song_demoter], animated: true)
		
		song_arranger.isEnabled = { switch albumListState.selectMode {
			case .view, .selectAlbums: return false
			case .selectSongs(let selectedIDs):
				if selectedIDs.isEmpty { return true }
				let selectedIndices: [Int64] = albumListState.songs(with: selectedIDs).map { $0.index }
				return selectedIndices.isConsecutive()
		}}()
		song_refreshArrangeMenu()
		song_promoter.isEnabled = { switch albumListState.selectMode {
			case .view, .selectAlbums: return false
			case .selectSongs(let selectedIDs): return !selectedIDs.isEmpty
		}}()
		song_demoter.isEnabled = song_promoter.isEnabled
	}
	
	// MARK: - Sorting
	
	private func album_refreshArrangeMenu() {
		album_arranger.preferredMenuElementOrder = .fixed
		
		let groups: [[AlbumOrder]] = [[.recentlyAdded, .newest, .artist], [.random, .reverse]]
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
		album_arranger.menu = UIMenu(children: submenus)
	}
	private func album_allowsArrange(by albumOrder: AlbumOrder) -> Bool {
		guard album_toArrange().count >= 2 else { return false }
		switch albumOrder {
			case .random, .reverse, .recentlyAdded, .artist: return true
			case .newest: return album_toArrange().contains {
				nil != MusicRepo.shared.musicKitSection($0.albumPersistentID)?.releaseDate
			}
		}
	}
	private func song_refreshArrangeMenu() {
		song_arranger.preferredMenuElementOrder = .fixed
		
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
		song_arranger.menu = UIMenu(children: submenus)
	}
	
	private func album_arrange(by albumOrder: AlbumOrder) {
		Task {
			let oldRows = albumListState.rowIdentifiers()
			albumOrder.reindex(album_toArrange())
			albumListState.refreshItems()
			switch albumListState.selectMode {
				case .selectSongs, .view: break
				case .selectAlbums: albumListState.selectMode = .selectAlbums([])
			}
			let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers())
		}
	}
	private func song_arrange(by songOrder: SongOrder) {
		Task {
			let oldRows = albumListState.rowIdentifiers()
			songOrder.reindex(song_toArrange())
			albumListState.refreshItems()
			switch albumListState.selectMode {
				case .selectAlbums, .view: break
				case .selectSongs: albumListState.selectMode = .selectSongs([])
			}
			let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers())
		}
	}
	
	private func album_toArrange() -> [Album] {
		switch albumListState.selectMode {
			case .selectSongs: return []
			case .view: break
			case .selectAlbums(let selectedIDs):
				if selectedIDs.isEmpty { break }
				return albumListState.albums(with: selectedIDs)
		}
		return albumListState.albums()
	}
	private func song_toArrange() -> [Song] {
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
			let selectedIndices: [Int64] = albumListState.albums(with: selectedIDs).map { $0.index }
			guard let front = selectedIndices.first, let back = selectedIndices.last else { return }
			
			let target: Int64 = selectedIndices.isConsecutive() ? max(front-1, 0) : front
			let range = (target...back)
			let inRange: [Album] = range.map { int64 in albumListState.albums()[Int(int64)] }
			let toPromote = inRange.filter { selectedIDs.contains($0.albumPersistentID) }
			let toDisplace = inRange.filter { !selectedIDs.contains($0.albumPersistentID) }
			let newBlock: [Album] = toPromote + toDisplace
			let oldRows = albumListState.rowIdentifiers()
			
			newBlock.indices.forEach { offset in
				newBlock[offset].index = target + Int64(offset)
			}
			albumListState.refreshItems()
			NotificationCenter.default.post(name: AlbumListState.selectingAlbums, object: albumListState) // We didn’t change which albums were selected, but we made them contiguous, which should enable sorting.
			let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers(), runningBeforeContinuation: {
				self.tableView.scrollToRow(at: IndexPath(row: Int(target), section: 0), at: .middle, animated: true)
			})
		}
	}
	private func song_promote() {
		Task {
			guard case let .selectSongs(selectedIDs) = albumListState.selectMode else { return }
			let selectedIndices: [Int64] = albumListState.songs(with: selectedIDs).map { $0.index }
			guard let front = selectedIndices.first, let back = selectedIndices.last else { return }
			
			let target: Int64 = selectedIndices.isConsecutive() ? max(front-1, 0) : front
			let range = (target...back)
			let inRange: [Song] = range.map { int64 in albumListState.songs()[Int(int64)] }
			let toPromote = inRange.filter { selectedIDs.contains($0.persistentID) }
			let toDisplace = inRange.filter { !selectedIDs.contains($0.persistentID) }
			let newBlock: [Song] = toPromote + toDisplace
			let oldRows = albumListState.rowIdentifiers()
			
			newBlock.indices.forEach { offset in
				newBlock[offset].index = target + Int64(offset)
			}
			albumListState.refreshItems()
			NotificationCenter.default.post(name: AlbumListState.selectingSongs, object: albumListState)
			let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers(), runningBeforeContinuation: {
				guard
					let frontSong = newBlock.first,
					let targetRow = self.albumListState.items.firstIndex(where: { switch $0 {
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
			let selectedIndices: [Int64] = albumListState.albums(with: selectedIDs).map { $0.index }
			guard let front = selectedIndices.first, let back = selectedIndices.last else { return }
			
			let target: Int64 = selectedIndices.isConsecutive() ? min(back+1, Int64(albumListState.albums().count)-1) : back
			let range = (front...target)
			let inRange: [Album] = range.map { int64 in albumListState.albums()[Int(int64)] }
			let toDemote = inRange.filter { selectedIDs.contains($0.albumPersistentID) }
			let toDisplace = inRange.filter { !selectedIDs.contains($0.albumPersistentID) }
			let newBlock: [Album] = toDisplace + toDemote
			let oldRows = albumListState.rowIdentifiers()
			
			newBlock.indices.forEach { offset in
				newBlock[offset].index = front + Int64(offset)
			}
			albumListState.refreshItems()
			NotificationCenter.default.post(name: AlbumListState.selectingAlbums, object: albumListState)
			let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers(), runningBeforeContinuation: {
				self.tableView.scrollToRow(at: IndexPath(row: Int(target), section: 0), at: .middle, animated: true)
			})
		}
	}
	private func song_demote() {
		Task {
			guard case let .selectSongs(selectedIDs) = albumListState.selectMode else { return }
			let selectedIndices: [Int64] = albumListState.songs(with: selectedIDs).map { $0.index }
			guard let front = selectedIndices.first, let back = selectedIndices.last else { return }
			
			let target: Int64 = selectedIndices.isConsecutive() ? min(back+1, Int64(albumListState.songs().count)-1) : back
			let range = (front...target)
			let inRange: [Song] = range.map { int64 in albumListState.songs()[Int(int64)] }
			let toDemote = inRange.filter { selectedIDs.contains($0.persistentID) }
			let toDisplace = inRange.filter { !selectedIDs.contains($0.persistentID) }
			let newBlock: [Song] = toDisplace + toDemote
			let oldRows = albumListState.rowIdentifiers()
			
			newBlock.indices.forEach { offset in
				newBlock[offset].index = front + Int64(offset)
			}
			albumListState.refreshItems()
			NotificationCenter.default.post(name: AlbumListState.selectingSongs, object: albumListState)
			let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers(), runningBeforeContinuation: {
				guard
					let backSong = newBlock.last,
					let targetRow = self.albumListState.items.firstIndex(where: { switch $0 {
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
			let selectedIndices: [Int64] = albumListState.albums(with: selectedIDs).map { $0.index }
			guard let back = selectedIndices.last else { return }
			
			let range = (0...back)
			let inRange: [Album] = range.map { int64 in albumListState.albums()[Int(int64)] }
			let toFloat = inRange.filter { selectedIDs.contains($0.albumPersistentID) }
			let toDisplace = inRange.filter { !selectedIDs.contains($0.albumPersistentID) }
			let newBlock: [Album] = toFloat + toDisplace
			let oldRows = albumListState.rowIdentifiers()
			
			albumListState.selectMode = .selectAlbums([])
			newBlock.indices.forEach { offset in
				newBlock[offset].index = Int64(offset)
			}
			albumListState.refreshItems()
			let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers())
		}
	}
	private func song_float() {
		Task {
			guard case let .selectSongs(selectedIDs) = albumListState.selectMode else { return }
			let selectedIndices: [Int64] = albumListState.songs(with: selectedIDs).map { $0.index }
			guard let back = selectedIndices.last else { return }
			
			let range = (0...back)
			let inRange: [Song] = range.map { int64 in albumListState.songs()[Int(int64)] }
			let toFloat = inRange.filter { selectedIDs.contains($0.persistentID) }
			let toDisplace = inRange.filter { !selectedIDs.contains($0.persistentID) }
			let newBlock: [Song] = toFloat + toDisplace
			let oldRows = albumListState.rowIdentifiers()
			
			albumListState.selectMode = .selectSongs([])
			newBlock.indices.forEach { offset in
				newBlock[offset].index = Int64(offset)
			}
			albumListState.refreshItems()
			let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers())
		}
	}
	
	private func album_sink() {
		Task {
			guard case let .selectAlbums(selectedIDs) = albumListState.selectMode else { return }
			let selectedIndices: [Int64] = albumListState.albums(with: selectedIDs).map { $0.index }
			guard let front = selectedIndices.first else { return }
			
			let range = (front...Int64(albumListState.albums().count)-1)
			let inRange: [Album] = range.map { int64 in albumListState.albums()[Int(int64)] }
			let toSink = inRange.filter { selectedIDs.contains($0.albumPersistentID) }
			let toDisplace = inRange.filter { !selectedIDs.contains($0.albumPersistentID) }
			let newBlock: [Album] = toDisplace + toSink
			let oldRows = albumListState.rowIdentifiers()
			
			albumListState.selectMode = .selectAlbums([])
			newBlock.indices.forEach { offset in
				newBlock[offset].index = front + Int64(offset)
			}
			albumListState.refreshItems()
			let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers())
		}
	}
	private func song_sink() {
		Task {
			guard case let .selectSongs(selectedIDs) = albumListState.selectMode else { return }
			let selectedIndices: [Int64] = albumListState.songs(with: selectedIDs).map { $0.index }
			guard let front = selectedIndices.first else { return }
			
			let range = (front...(Int64(albumListState.songs().count)-1))
			let inRange: [Song] = range.map { int64 in albumListState.songs()[Int(int64)] }
			let toSink = inRange.filter { selectedIDs.contains($0.persistentID) }
			let toDisplace = inRange.filter { !selectedIDs.contains($0.persistentID) }
			let newBlock: [Song] = toDisplace + toSink
			let oldRows = albumListState.rowIdentifiers()
			
			albumListState.selectMode = .selectSongs([])
			newBlock.indices.forEach { offset in
				newBlock[offset].index = front + Int64(offset)
			}
			albumListState.refreshItems()
			let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers())
		}
	}
}
