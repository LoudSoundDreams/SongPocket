// 2020-04-28

import UIKit
import SwiftUI
import MusicKit
import MediaPlayer
import CoreData

@MainActor @Observable final class AlbumListState {
	@ObservationIgnored var albums: [AlbumID: Album] = AlbumListState.freshAlbums()
	var current: State = .view { didSet {
		NotificationCenter.default.post(name: Self.changed, object: self)
	}}
	enum State {
		case view
		case edit(Set<AlbumID>)
	}
}
extension AlbumListState {
	static let changed = Notification.Name("LRAlbumListStateChanged")
	func rowIdentifiers() -> [AnyHashable] {
		// 10,000 albums takes 22ms in 2024.
		return albums.values.sorted { $0.index < $1.index }.map { $0.objectID }
	}
	static func freshAlbums() -> [AlbumID: Album] {
		// 10,000 albums takes 10ms in 2024.
		let allAlbums = Database.viewContext.fetchPlease(Album.fetchRequest())
		let tuples = allAlbums.map { ($0.albumPersistentID, $0) }
		return Dictionary(uniqueKeysWithValues: tuples)
	}
}

// MARK: - Table view controller

final class AlbumsTVC: LibraryTVC {
	private let albumListState = AlbumListState()
	
	private lazy var arrangeButton = UIBarButtonItem(title: InterfaceText.sort, image: UIImage(systemName: "arrow.up.arrow.down"))
	private lazy var promoteButton = UIBarButtonItem(title: InterfaceText.moveUp, image: UIImage(systemName: "chevron.up"), primaryAction: UIAction { [weak self] _ in self?.promote() }, menu: UIMenu(children: [UIAction(title: InterfaceText.moveToTop, image: UIImage(systemName: "arrow.up.to.line")) { [weak self] _ in self?.float() }]))
	private lazy var demoteButton = UIBarButtonItem(title: InterfaceText.moveDown, image: UIImage(systemName: "chevron.down"), primaryAction: UIAction { [weak self] _ in self?.demote() }, menu: UIMenu(children: [UIAction(title: InterfaceText.moveToBottom, image: UIImage(systemName: "arrow.down.to.line")) { [weak self] _ in self?.sink() }]))
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		editingButtons = [editButtonItem, .flexibleSpace(), arrangeButton, .flexibleSpace(), promoteButton, .flexibleSpace(), demoteButton]
		
		super.viewDidLoad()
		
		navigationItem.backButtonDisplayMode = .minimal
		tableView.separatorStyle = .none
		
		NotificationCenter.default.addObserverOnce(self, selector: #selector(activateAlbum), name: AlbumRow.activateAlbum, object: nil)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(refreshEditingButtons), name: AlbumListState.changed, object: albumListState)
		__MainToolbar.shared.albumsTVC = WeakRef(self)
	}
	@objc private func activateAlbum(notification: Notification) {
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
			guard 
				let cell = tableView.cellForRow(at: indexPath),
				let rowAlbum = albumListState.albums.values.first(where: { album in
					indexPath.row == album.index
				})
			else { return }
			cell.contentConfiguration = UIHostingConfiguration {
				AlbumRow(
					album: rowAlbum,
					viewportWidth: size.width,
					viewportHeight: size.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom,
					albumListState: albumListState)
			}.margins(.all, .zero)
		}
	}
	
	func showCurrent() {
		guard
			let uInt64 = MPMusicPlayerController._system?.nowPlayingItem?.albumPersistentID,
			let currentAlbum = albumListState.albums[AlbumID(bitPattern: uInt64)]
		else { return }
		// The current song might not be in our database, but the current `Album` is.
		navigationController?.popToRootViewController(animated: true)
		let indexPath = IndexPath(row: Int(currentAlbum.index), section: 0)
		tableView.scrollToRow(at: indexPath, at: .top, animated: true)
	}
	
	override func refreshLibraryItems() {
		Task {
			// TO DO: Does this need to be in a `Task`?
			let oldRows = albumListState.rowIdentifiers()
			albumListState.albums = AlbumListState.freshAlbums()
			guard !albumListState.albums.isEmpty else {
				reflectNoAlbums()
				return
			}
			switch albumListState.current {
				case .view: break
				case .edit: albumListState.current = .edit([]) // If in editing mode, deselects everything and stays in editing mode
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
		guard let rowAlbum = albumListState.albums.values.first(where: { album in
			// Bad time complexity, but scanning among 10,000 albums takes 0.6ms at worst and 0.3ms on average in 2024.
			indexPath.row == album.index
		}) else { return UITableViewCell() }
		return configuredCellForAlbum(cell: cell, album: rowAlbum)
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
	
	// MARK: - Editing
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		albumListState.current = editing ? .edit([]) : .view
	}
	
	@objc override func refreshEditingButtons() {
		super.refreshEditingButtons()
		editButtonItem.isEnabled = !albumListState.albums.isEmpty && MusicAuthorization.currentStatus == .authorized // If the user revokes access, we’re showing the placeholder, but the view model is probably non-empty.
		arrangeButton.isEnabled = {
			switch albumListState.current {
				case .view: return false
				case .edit(let selected):
					if selected.isEmpty { return true }
					return selected.compactMap { albumListState.albums[$0]?.index }.sorted().isConsecutive()
			}
		}()
		arrangeButton.preferredMenuElementOrder = .fixed
		arrangeButton.menu = newArrangeMenu()
		promoteButton.isEnabled = {
			switch albumListState.current {
				case .view: return false
				case .edit(let selected): return !selected.isEmpty
			}
		}()
		demoteButton.isEnabled = promoteButton.isEnabled
	}
	
	private func newArrangeMenu() -> UIMenu {
		let groups: [[AlbumOrder]] = [
			[.recentlyAdded, .newest, .artist],
			[.random, .reverse],
		]
		let submenus: [UIMenu] = groups.map { group in
			UIMenu(options: .displayInline, children: group.map { order in
				UIDeferredMenuElement.uncached { [weak self] useElements in
					// Runs each time the button presents the menu
					guard let self else { return }
					let action = order.newUIAction(handler: { [weak self] in
						self?.arrange(by: order)
					})
					if !allowsArrange(by: order) {
						action.attributes.formUnion(.disabled) // You must do this inside `UIDeferredMenuElement.uncached`. `UIMenu` caches `UIAction.attributes`.
					}
					useElements([action])
				}
			})
		}
		return UIMenu(children: submenus)
	}
	private func allowsArrange(by order: AlbumOrder) -> Bool {
		guard toArrange().count >= 2 else { return false }
		switch order {
			case .random, .reverse: return true
			case .recentlyAdded, .artist: return true
			case .newest:
				return toArrange().contains {
					nil != $0.releaseDateEstimate
				}
		}
	}
	private func arrange(by order: AlbumOrder) {
		let oldRows = albumListState.rowIdentifiers()
		
		order.reindex(toArrange())
		albumListState.current = .edit([])
		Task { let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers()) }
	}
	private func toArrange() -> [Album] {
		switch albumListState.current {
			case .view: return []
			case .edit(let selected):
				if selected.isEmpty {
					return albumListState.albums.values.sorted { $0.index < $1.index }
				}
				return selected.compactMap { albumListState.albums[$0] }.sorted { $0.index < $1.index }
		}
	}
	
	private func promote() {
		guard case let .edit(selected) = albumListState.current else { return }
		let selectedIndicesSorted = selected.map { albumListState.albums[$0]!.index }.sorted()
		guard
			let front = selectedIndicesSorted.first,
			let back = selectedIndicesSorted.last
		else { return }
		
		let target: Int64 = selectedIndicesSorted.isConsecutive() ? max(front - 1, 0) : front
		let range = (target...back)
		let toAffectSorted = albumListState.albums.values.filter {
			range.contains($0.index)
		}.sorted { $0.index < $1.index }
		let toPromote = toAffectSorted.filter {
			selected.contains($0.albumPersistentID)
		}
		let toDisplace = toAffectSorted.filter {
			!selected.contains($0.albumPersistentID)
		}
		let newBlock = toPromote + toDisplace
		let oldRows = albumListState.rowIdentifiers()
		
		newBlock.indices.forEach { offset in
			newBlock[offset].index = target + Int64(offset)
		}
		Task {
			let _ = await moveRows(
				oldIdentifiers: oldRows,
				newIdentifiers: albumListState.rowIdentifiers(),
				runningBeforeContinuation: {
					self.tableView.scrollToRow(at: IndexPath(row: Int(target), section: 0), at: .middle, animated: true)
				})
		}
	}
	private func demote() {
		guard case let .edit(selected) = albumListState.current else { return }
		let selectedIndicesSorted = selected.map { albumListState.albums[$0]!.index }.sorted()
		guard
			let front = selectedIndicesSorted.first,
			let back = selectedIndicesSorted.last
		else { return }
		
		let target: Int64 = selectedIndicesSorted.isConsecutive() ? min(back + 1, Int64(albumListState.albums.count) - 1) : back
		let range = (front...target)
		let toAffectSorted = albumListState.albums.values.filter {
			range.contains($0.index)
		}.sorted { $0.index < $1.index }
		let toDemote = toAffectSorted.filter {
			selected.contains($0.albumPersistentID)
		}
		let toDisplace = toAffectSorted.filter {
			!selected.contains($0.albumPersistentID)
		}
		let newBlock = toDisplace + toDemote
		let oldRows = albumListState.rowIdentifiers()
		
		newBlock.indices.forEach { offset in
			newBlock[offset].index = front + Int64(offset)
		}
		Task {
			let _ = await moveRows(
				oldIdentifiers: oldRows,
				newIdentifiers: albumListState.rowIdentifiers(),
				runningBeforeContinuation: {
					self.tableView.scrollToRow(at: IndexPath(row: Int(target), section: 0), at: .middle, animated: true)
				})
		}
	}
	
	private func float() {
		guard case let .edit(selected) = albumListState.current else { return }
		let selectedIndicesSorted = selected.map { albumListState.albums[$0]!.index }.sorted()
		guard let back = selectedIndicesSorted.last else { return }
		
		let target: Int64 = 0
		let range = (target...back)
		let toAffectSorted = albumListState.albums.values.filter {
			range.contains($0.index)
		}.sorted { $0.index < $1.index }
		let toPromote = toAffectSorted.filter {
			selected.contains($0.albumPersistentID)
		}
		let toDisplace = toAffectSorted.filter {
			!selected.contains($0.albumPersistentID)
		}
		let newBlock = toPromote + toDisplace
		let oldRows = albumListState.rowIdentifiers()
		
		albumListState.current = .edit([])
		newBlock.indices.forEach { offset in
			newBlock[offset].index = target + Int64(offset)
		}
		Task { let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers()) }
	}
	private func sink() {
		guard case let .edit(selected) = albumListState.current else { return }
		let selectedIndicesSorted = selected.map { albumListState.albums[$0]!.index }.sorted()
		guard let front = selectedIndicesSorted.first else { return }
		
		let target: Int64 = Int64(albumListState.albums.count) - 1
		let range = (front...target)
		let toAffectSorted = albumListState.albums.values.filter {
			range.contains($0.index)
		}.sorted { $0.index < $1.index }
		let toDemote = toAffectSorted.filter {
			selected.contains($0.albumPersistentID)
		}
		let toDisplace = toAffectSorted.filter {
			!selected.contains($0.albumPersistentID)
		}
		let newBlock = toDisplace + toDemote
		let oldRows = albumListState.rowIdentifiers()
		
		albumListState.current = .edit([])
		newBlock.indices.forEach { offset in
			newBlock[offset].index = front + Int64(offset)
		}
		Task { let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers()) }
	}
}
