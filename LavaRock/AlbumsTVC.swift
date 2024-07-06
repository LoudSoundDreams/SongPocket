// 2020-04-28

import UIKit
import SwiftUI
import MusicKit
import MediaPlayer
import CoreData

@MainActor @Observable final class AlbumListState {
	@ObservationIgnored fileprivate var albums: [Album] = AlbumListState.freshAlbums()
	var selectMode: SelectMode = .view { didSet {
		switch selectMode {
			case .view: break
			case .selectAlbums: NotificationCenter.default.post(name: Self.selectingAlbums, object: self)
		}
	}}
}
extension AlbumListState {
	fileprivate func refreshAlbums() {
		albums = Self.freshAlbums()
	}
	private static func freshAlbums() -> [Album] {
		return Database.viewContext.fetchPlease(Album.fetchRequest_sorted())
	}
	fileprivate func rowIdentifiers() -> [AnyHashable] {
		return albums.map { $0.objectID }
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
	private let arrangeButton = UIBarButtonItem(title: InterfaceText.sort, image: UIImage(systemName: "arrow.up.arrow.down"))
	private lazy var promoteButton = UIBarButtonItem(title: InterfaceText.moveUp, image: UIImage(systemName: "chevron.up"), primaryAction: UIAction { [weak self] _ in self?.promote() }, menu: UIMenu(children: [UIAction(title: InterfaceText.toTop, image: UIImage(systemName: "arrow.up.to.line")) { [weak self] _ in self?.float() }]))
	private lazy var demoteButton = UIBarButtonItem(title: InterfaceText.moveDown, image: UIImage(systemName: "chevron.down"), primaryAction: UIAction { [weak self] _ in self?.demote() }, menu: UIMenu(children: [UIAction(title: InterfaceText.toBottom, image: UIImage(systemName: "arrow.down.to.line")) { [weak self] _ in self?.sink() }]))
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = UIColor(.grey_oneEighth)
		tableView.separatorStyle = .none
		endSelecting()
		
		selectButton.isEnabled = allowsSelect()
		navigationItem.backButtonDisplayMode = .minimal
		
		NotificationCenter.default.addObserverOnce(self, selector: #selector(mergedChanges), name: MusicRepo.mergedChanges, object: nil)
		__MainToolbar.shared.albumsTVC = WeakRef(self)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(openAlbumID), name: AlbumRow.openAlbumID, object: nil)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(reflectSelectedAlbums), name: AlbumListState.selectingAlbums, object: albumListState)
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
			if albumListState.albums.isEmpty {
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
		return albumListState.albums.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		// The cell in the storyboard is completely default except for the reuse identifier.
		let cell = tableView.dequeueReusableCell(withIdentifier: "Album Card", for: indexPath)
		let rowAlbum = albumListState.albums[indexPath.row]
		return cellForAlbum(cell: cell, album: rowAlbum)
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
			let rowAlbum = albumListState.albums[indexPath.row]
			cell.contentConfiguration = UIHostingConfiguration {
				AlbumRow(
					albumID: rowAlbum.albumPersistentID,
					viewportWidth: size.width,
					viewportHeight: size.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom,
					albumListState: albumListState)
			}.margins(.all, .zero)
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
		albumListState.refreshAlbums()
		selectButton.isEnabled = allowsSelect()
		switch albumListState.selectMode {
			case .view: break
			case .selectAlbums(let selectedAlbumIDs):
				let newSelected: Set<AlbumID> = Set(albumListState.albums.compactMap {
					let albumID = $0.albumPersistentID
					guard selectedAlbumIDs.contains(albumID) else { return nil }
					return albumID
				})
				albumListState.selectMode = .selectAlbums(newSelected)
		}
		guard !albumListState.albums.isEmpty else {
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
		guard let currentAlbum = albumListState.albums.first(where: { album in
			currentAlbumID == album.albumPersistentID
		}) else { return }
		// The current song might not be in our database, but the current `Album` is.
		let indexPath = IndexPath(row: Int(currentAlbum.index), section: 0)
		tableView.scrollToRow(at: indexPath, at: .top, animated: true)
	}
	
	@objc private func openAlbumID(notification: Notification) {
		guard
			let albumIDToOpen = notification.object as? AlbumID,
			let albumToOpen = albumListState.albums.first(where: { album in
				albumIDToOpen == album.albumPersistentID
			})
		else { return }
		navigationController?.pushViewController({
			let songsTVC = UIStoryboard(name: "SongsTVC", bundle: nil).instantiateInitialViewController() as! SongsTVC
			songsTVC.songsViewModel = SongsViewModel(album: albumToOpen)
			return songsTVC
		}(), animated: true)
	}
	
	// MARK: - Editing
	
	private func allowsSelect() -> Bool {
		return !albumListState.albums.isEmpty && MusicAuthorization.currentStatus == .authorized // If the user revokes access, we’re showing the placeholder, but the view model is probably non-empty.
	}
	
	private func beginSelecting() {
		setToolbarItems([selectButton, .flexibleSpace(), arrangeButton, .flexibleSpace(), promoteButton, .flexibleSpace(), demoteButton], animated: true)
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
	
	@objc private func reflectSelectedAlbums() {
		arrangeButton.isEnabled = {
			switch albumListState.selectMode {
				case .view: return false
				case .selectAlbums(let selectedAlbumIDs):
					if selectedAlbumIDs.isEmpty { return true }
					let selectedIndices = albumListState.albums.filter { selectedAlbumIDs.contains($0.albumPersistentID) }.map { $0.index }
					return selectedIndices.isConsecutive()
			}
		}()
		arrangeButton.preferredMenuElementOrder = .fixed
		arrangeButton.menu = newArrangeMenu()
		promoteButton.isEnabled = {
			switch albumListState.selectMode {
				case .view: return false
				case .selectAlbums(let selectedAlbumIDs): return !selectedAlbumIDs.isEmpty
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
		albumListState.refreshAlbums()
		albumListState.selectMode = .selectAlbums([])
		Task { let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers()) }
	}
	private func toArrange() -> [Album] {
		switch albumListState.selectMode {
			case .view: return []
			case .selectAlbums(let selectedAlbumIDs):
				if selectedAlbumIDs.isEmpty { return albumListState.albums }
				return albumListState.albums.filter { selectedAlbumIDs.contains($0.albumPersistentID) }
		}
	}
	
	private func promote() {
		guard case let .selectAlbums(selectedAlbumIDs) = albumListState.selectMode else { return }
		let selectedIndices = albumListState.albums.filter { selectedAlbumIDs.contains($0.albumPersistentID) }.map { $0.index }
		guard
			let front = selectedIndices.first,
			let back = selectedIndices.last
		else { return }
		
		let target: Int64 = selectedIndices.isConsecutive() ? max(front - 1, 0) : front
		let range = (target...back)
		let toAffect = albumListState.albums.filter { range.contains($0.index) }
		let toPromote = toAffect.filter { selectedAlbumIDs.contains($0.albumPersistentID) }
		let toDisplace = toAffect.filter { !selectedAlbumIDs.contains($0.albumPersistentID) }
		let newBlock = toPromote + toDisplace
		let oldRows = albumListState.rowIdentifiers()
		
		newBlock.indices.forEach { offset in
			newBlock[offset].index = target + Int64(offset)
		}
		albumListState.refreshAlbums()
		Task {
			let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers(), runningBeforeContinuation: {
				self.tableView.scrollToRow(at: IndexPath(row: Int(target), section: 0), at: .middle, animated: true)
			})
		}
	}
	private func demote() {
		guard case let .selectAlbums(selectedAlbumIDs) = albumListState.selectMode else { return }
		let selectedIndices = albumListState.albums.filter { selectedAlbumIDs.contains($0.albumPersistentID) }.map { $0.index }
		guard
			let front = selectedIndices.first,
			let back = selectedIndices.last
		else { return }
		
		let target: Int64 = selectedIndices.isConsecutive() ? min(back + 1, Int64(albumListState.albums.count) - 1) : back
		let range = (front...target)
		let toAffect = albumListState.albums.filter { range.contains($0.index) }
		let toDemote = toAffect.filter { selectedAlbumIDs.contains($0.albumPersistentID) }
		let toDisplace = toAffect.filter { !selectedAlbumIDs.contains($0.albumPersistentID) }
		let newBlock = toDisplace + toDemote
		let oldRows = albumListState.rowIdentifiers()
		
		newBlock.indices.forEach { offset in
			newBlock[offset].index = front + Int64(offset)
		}
		albumListState.refreshAlbums()
		Task {
			let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers(), runningBeforeContinuation: {
				self.tableView.scrollToRow(at: IndexPath(row: Int(target), section: 0), at: .middle, animated: true)
			})
		}
	}
	
	private func float() {
		guard case let .selectAlbums(selectedAlbumIDs) = albumListState.selectMode else { return }
		let selectedIndices = albumListState.albums.filter { selectedAlbumIDs.contains($0.albumPersistentID) }.map { $0.index }
		guard let back = selectedIndices.last else { return }
		
		let target: Int64 = 0
		let range = (target...back)
		let toAffect = albumListState.albums.filter { range.contains($0.index) }
		let toPromote = toAffect.filter { selectedAlbumIDs.contains($0.albumPersistentID) }
		let toDisplace = toAffect.filter { !selectedAlbumIDs.contains($0.albumPersistentID) }
		let newBlock = toPromote + toDisplace
		let oldRows = albumListState.rowIdentifiers()
		
		albumListState.selectMode = .selectAlbums([])
		newBlock.indices.forEach { offset in
			newBlock[offset].index = target + Int64(offset)
		}
		albumListState.refreshAlbums()
		Task { let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers()) }
	}
	private func sink() {
		guard case let .selectAlbums(selectedAlbumIDs) = albumListState.selectMode else { return }
		let selectedIndices = albumListState.albums.filter { selectedAlbumIDs.contains($0.albumPersistentID) }.map { $0.index }
		guard let front = selectedIndices.first else { return }
		
		let target: Int64 = Int64(albumListState.albums.count) - 1
		let range = (front...target)
		let toAffect = albumListState.albums.filter { range.contains($0.index) }
		let toDemote = toAffect.filter { selectedAlbumIDs.contains($0.albumPersistentID) }
		let toDisplace = toAffect.filter { !selectedAlbumIDs.contains($0.albumPersistentID) }
		let newBlock = toDisplace + toDemote
		let oldRows = albumListState.rowIdentifiers()
		
		albumListState.selectMode = .selectAlbums([])
		newBlock.indices.forEach { offset in
			newBlock[offset].index = front + Int64(offset)
		}
		albumListState.refreshAlbums()
		Task { let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: albumListState.rowIdentifiers()) }
	}
}
