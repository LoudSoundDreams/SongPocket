// 2020-05-04

import UIKit
import SwiftUI
import CoreData

@MainActor struct SongsViewModel {
	static let prerowCount = 1
	
	var songs: [Song] { didSet {
		Database.renumber(songs)
	}}
	func rowIdentifiers() -> [AnyHashable] {
		let itemRowIDs = songs.map { AnyHashable($0.objectID) }
		return [42] + itemRowIDs
	}
	func withRefreshedData() -> Self {
		// Get the `Album` from the first non-deleted `Song`.
		guard let album = songs.first(where: { nil != $0.container })?.container else {
			return Self(songs: [])
		}
		return Self(album: album)
	}
}
extension SongsViewModel {
	init(album: Album) { songs = album.songs(sorted: true) }
}

@MainActor @Observable final class SongListState {
	var selectMode: SelectMode = .view(nil) { didSet {
		switch selectMode {
			case .view: break
			case .select: NotificationCenter.default.post(name: Self.selecting, object: self)
		}
	}}
}
extension SongListState {
	static let selecting = Notification.Name("LRSelectingSongs")
	enum SelectMode: Equatable {
		case view(SongID?)
		case select(Set<Int64>)
	}
}

// MARK: - Table view controller

final class SongsTVC: LibraryTVC {
	var songsViewModel: SongsViewModel! = nil
	private let songListState = SongListState()
	
	private let selectButton = UIBarButtonItem()
	private let arrangeButton = UIBarButtonItem(title: InterfaceText.sort, image: UIImage(systemName: "arrow.up.arrow.down"))
	private lazy var promoteButton = UIBarButtonItem(title: InterfaceText.moveUp, image: UIImage(systemName: "chevron.up"), primaryAction: UIAction { [weak self] _ in self?.promote() }, menu: UIMenu(children: [UIAction(title: InterfaceText.toTop, image: UIImage(systemName: "arrow.up.to.line")) { [weak self] _ in self?.float() }]))
	private lazy var demoteButton = UIBarButtonItem(title: InterfaceText.moveDown, image: UIImage(systemName: "chevron.down"), primaryAction: UIAction { [weak self] _ in self?.demote() }, menu: UIMenu(children: [UIAction(title: InterfaceText.toBottom, image: UIImage(systemName: "arrow.down.to.line")) { [weak self] _ in self?.sink() }]))
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = UIColor(.grey_oneEighth)
		tableView.separatorStyle = .none
		endSelecting()
		
		NotificationCenter.default.addObserverOnce(self, selector: #selector(reflectSelected), name: SongListState.selecting, object: songListState)
	}
	
	// MARK: - Table view
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		if songsViewModel.songs.isEmpty {
			contentUnavailableConfiguration = UIHostingConfiguration {
				Image(systemName: "music.note")
					.foregroundStyle(.secondary)
					.font(.title)
			}
		} else {
			contentUnavailableConfiguration = nil
		}
		
		return 1
	}
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if songsViewModel.songs.isEmpty {
			return 0 // Without `prerowCount`
		} else {
			return SongsViewModel.prerowCount + songsViewModel.songs.count
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let album = songsViewModel.songs.first!.container!
		switch indexPath.row {
			case 0:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(withIdentifier: "Album Header", for: indexPath)
				cell.selectionStyle = .none // So the user can’t even highlight the cell
				cell.backgroundColor = .clear
				cell.contentConfiguration = UIHostingConfiguration {
					AlbumHeader(albumID: album.albumPersistentID)
				}.margins(.all, .zero)
				return cell
			default:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(withIdentifier: "Song", for: indexPath)
				let song = songsViewModel.songs[indexPath.row - SongsViewModel.prerowCount]
				cell.backgroundColor = .clear
				cell.selectedBackgroundView = {
					let result = UIView()
					result.backgroundColor = .tintColor.withAlphaComponent(.oneHalf)
					return result
				}()
				cell.contentConfiguration = UIHostingConfiguration {
					Text(song.songInfo()?.titleOnDisk ?? "")
				}.margins(.all, .zero)
				return cell
		}
	}
	
	override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? { return nil }
	
	// MARK: - Editing
	
	private func beginSelecting() {
		setToolbarItems([selectButton, .flexibleSpace(), arrangeButton, .flexibleSpace(), promoteButton, .flexibleSpace(), demoteButton], animated: true)
		songListState.selectMode = .select([])
		navigationItem.setLeftBarButtonItems([.flexibleSpace()], animated: true) // Removes “Back” button
		selectButton.primaryAction = UIAction(title: InterfaceText.done, image: Self.endSelectingImage) { [weak self] _ in self?.endSelecting() }
	}
	private func endSelecting() {
		Database.viewContext.savePlease()
		
		setToolbarItems([selectButton] + __MainToolbar.shared.barButtonItems, animated: true)
		songListState.selectMode = .view(nil)
		navigationItem.setLeftBarButtonItems([], animated: true)
		selectButton.primaryAction = UIAction(title: InterfaceText.select, image: Self.beginSelectingImage) { [weak self] _ in self?.beginSelecting() }
	}
	
	@objc private func reflectSelected() {
		arrangeButton.isEnabled = {
			switch songListState.selectMode {
				case .view: return false
				case .select(let selected):
					if selected.isEmpty { return true }
					return selected.sorted().isConsecutive()
			}
		}()
		arrangeButton.preferredMenuElementOrder = .fixed
		arrangeButton.menu = newArrangeMenu()
		promoteButton.isEnabled = {
			switch songListState.selectMode {
				case .view: return false
				case .select(let selected): return !selected.isEmpty
			}
		}()
		demoteButton.isEnabled = promoteButton.isEnabled
	}
	
	private func newArrangeMenu() -> UIMenu {
		let groups: [[SongOrder]] = [
			[.track],
			[.random, .reverse],
		]
		let submenus: [UIMenu] = groups.map { group in
			UIMenu(options: .displayInline, children: group.map { order in
				UIDeferredMenuElement.uncached { [weak self] useElements in
					guard let self else { return }
					let action = order.newUIAction(handler: { [weak self] in
						self?.arrange(by: order)
					})
					if toArrange().count <= 1 {
						action.attributes.formUnion(.disabled)
					}
					useElements([action])
				}
			})
		}
		return UIMenu(children: submenus)
	}
	private func arrange(by order: SongOrder) {
		let oldRows = songsViewModel.rowIdentifiers()
		
		order.reindex(toArrange())
		songsViewModel = songsViewModel.withRefreshedData()
		songListState.selectMode = .select([])
		Task { let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: songsViewModel.rowIdentifiers()) }
	}
	private func toArrange() -> [Song] {
		switch songListState.selectMode {
			case .view: return []
			case .select(let selected):
				if selected.isEmpty {
					return songsViewModel.songs
				}
				return selected.map { songsViewModel.songs[Int($0)] }.sorted { $0.index < $1.index }
		}
	}
	
	private func promote() {
		guard case let .select(selected) = songListState.selectMode else { return }
		let indicesSorted = selected.sorted().map { Int($0) }
		guard let frontmostIndex = indicesSorted.first else { return }
		let oldRows = songsViewModel.rowIdentifiers()
		var newSongs = songsViewModel.songs
		let targetIndex: Int = indicesSorted.isConsecutive() ? max(0, frontmostIndex - 1) : frontmostIndex
		
		songListState.selectMode = .select(Set(
			Int64(targetIndex) ... Int64((targetIndex + indicesSorted.count - 1))
		))
		newSongs.move(fromOffsets: IndexSet(indicesSorted), toOffset: Int(targetIndex))
		songsViewModel.songs = newSongs
		Task {
			let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: songsViewModel.rowIdentifiers(), runningBeforeContinuation: {
				self.tableView.scrollToRow(at: IndexPath(row: SongsViewModel.prerowCount + targetIndex, section: 0), at: .middle, animated: true)
			})
		}
	}
	func demote() {
		guard case let .select(selected) = songListState.selectMode else { return }
		let indicesSorted = selected.sorted().map { Int($0) }
		guard let backmostIndex = indicesSorted.last else { return }
		let oldRows = songsViewModel.rowIdentifiers()
		var newSongs = songsViewModel.songs
		let targetIndex: Int = indicesSorted.isConsecutive() ? min(songsViewModel.songs.count - 1, backmostIndex + 1) : backmostIndex
		
		songListState.selectMode = .select(Set(
			Int64(targetIndex - indicesSorted.count + 1) ... Int64(targetIndex)
		))
		newSongs.move(fromOffsets: IndexSet(indicesSorted), toOffset: targetIndex + 1)
		songsViewModel.songs = newSongs
		Task {
			let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: songsViewModel.rowIdentifiers(), runningBeforeContinuation: {
				self.tableView.scrollToRow(at: IndexPath(row: SongsViewModel.prerowCount + targetIndex, section: 0), at: .middle, animated: true)
			})
		}
	}
	
	private func float() {
		guard case let .select(selected) = songListState.selectMode else { return }
		let selectedUnordered = selected.map { Int($0) }
		let oldRows = songsViewModel.rowIdentifiers()
		var newSongs = songsViewModel.songs
		
		songListState.selectMode = .select([])
		newSongs.move(fromOffsets: IndexSet(selectedUnordered), toOffset: 0)
		songsViewModel.songs = newSongs
		Task { let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: songsViewModel.rowIdentifiers()) }
	}
	private func sink() {
		guard case let .select(selected) = songListState.selectMode else { return }
		let selectedUnordered = selected.map { Int($0) }
		let oldRows = songsViewModel.rowIdentifiers()
		var newSongs = songsViewModel.songs
		
		songListState.selectMode = .select([])
		newSongs.move(fromOffsets: IndexSet(selectedUnordered), toOffset: newSongs.count)
		songsViewModel.songs = newSongs
		Task { let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: songsViewModel.rowIdentifiers()) }
	}
}
