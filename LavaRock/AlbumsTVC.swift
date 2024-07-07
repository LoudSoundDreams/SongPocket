// 2020-04-28

import UIKit
import SwiftUI
import MusicKit
import MediaPlayer
import CoreData

@MainActor @Observable final class AlbumListState {
	@ObservationIgnored fileprivate var items: [Item] = AlbumListState.freshAlbums().map { .album($0) } // Retain old items until we explicitly refresh them, so we can diff them for updating the table view.
	var expansion: Expansion = .collapsed
	var selectMode: SelectMode = .view(nil) { didSet {
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
	
	enum SelectMode: Equatable {
		case view(SongID?)
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
		
		NotificationCenter.default.addObserverOnce(self, selector: #selector(refreshLibraryItems), name: MusicRepo.mergedChanges, object: nil)
		__MainToolbar.shared.albumsTVC = WeakRef(self)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(expandAlbumID), name: AlbumRow.expandAlbumID, object: nil)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(collapse), name: AlbumRow.collapse, object: nil)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(confirmPlay), name: SongRow.confirmPlaySongID, object: nil)
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
						// The cell in the storyboard is completely default except for the reuse identifier.
						let cell = tableView.dequeueReusableCell(withIdentifier: "Inline Song", for: indexPath)
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
								albumListState: albumListState)
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
	
	@objc private func refreshLibraryItems() {
		// WARNING: Is the user in the middle of a content-dependent interaction, like moving or renaming items? If so, wait until they finish before proceeding, or abort that interaction.
		
		let oldRows = albumListState.rowIdentifiers()
		albumListState.refreshItems()
		selectButton.isEnabled = allowsSelect()
		switch albumListState.selectMode {
			case .view(let activatedSongID):
				var newActivated = activatedSongID
				if let activatedSongID, !albumListState.items.contains(where: { switch $0 {
					case .album: return false
					case .song(let song): return activatedSongID == song.persistentID
				}}) {
					dismiss(animated: true) // In case “confirm play” action sheet is presented.
					newActivated = nil
				}
				albumListState.selectMode = .view(newActivated)
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
		Task {
			// TO DO: Keep current content visible
			guard await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers()) else { return }
			
			// Update the data within each row, which might be outdated.
			tableView.reconfigureRows(at: tableView.allIndexPaths())
		}
	}
	private func reflectNoAlbums() {
		tableView.deleteRows(at: tableView.allIndexPaths(), with: .middle)
		endSelecting()
	}
	
	func showCurrent() {
		guard let uInt64 = MPMusicPlayerController._system?.nowPlayingItem?.albumPersistentID else { return }
		let currentAlbumID = AlbumID(bitPattern: uInt64)
		guard let currentRow = albumListState.items.firstIndex(where: { switch $0 {
			case .song: return false
			case .album(let album): return currentAlbumID == album.albumPersistentID
		}}) else { return }
		// The current song might not be in our database, but the current `Album` is.
		let indexPath = IndexPath(row: currentRow, section: 0)
		tableView.performBatchUpdates {
			tableView.scrollToRow(at: indexPath, at: .top, animated: true)
		} completion: { _ in
			self.expandAndAlignTo(currentAlbumID)
		}
	}
	
	@objc private func expandAlbumID(notification: Notification) {
		guard let idToOpen = notification.object as? AlbumID else { return }
		expandAndAlignTo(idToOpen)
	}
	private func expandAndAlignTo(_ idToExpand: AlbumID) {
		let oldRows = albumListState.rowIdentifiers()
		
		albumListState.expansion = .expanded(idToExpand)
		albumListState.refreshItems()
		Task {
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
		let oldRows = albumListState.rowIdentifiers()
		
		albumListState.expansion = .collapsed
		albumListState.refreshItems()
		Task { let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers()) }
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
					guard let chosenSong: Song = { () -> Song? in
						for item in self.albumListState.items { switch item {
							case .album: continue
							case .song(let song):
								if chosenSongID == song.persistentID { return song }
						}}
						return nil
					}() else { return }
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
			albumListState.selectMode = .view(nil)
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
