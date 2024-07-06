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
			case .select: NotificationCenter.default.post(name: Self.selected, object: self)
		}
	}}
}
extension SongListState {
	static let selected = Notification.Name("LRSongsSelected")
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
		
		NotificationCenter.default.addObserverOnce(self, selector: #selector(refreshLibraryItems), name: MusicRepo.mergedChanges, object: nil)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(confirmPlay), name: SongRow.confirmPlaySongID, object: nil)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(reflectSelected), name: SongListState.selected, object: songListState)
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
					SongRow(song: song, albumID: album.albumPersistentID, songListState: songListState)
				}.margins(.all, .zero)
				return cell
		}
	}
	
	override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? { return nil }
	
	// MARK: - Events
	
	@objc private func refreshLibraryItems() {
		Task {
			let oldRows = songsViewModel.rowIdentifiers()
			songsViewModel = songsViewModel.withRefreshedData()
			dismiss(animated: true) // In case “confirm play” action sheet is presented. Annoying: also dismisses overflow menu.
			switch songListState.selectMode {
				case .view: songListState.selectMode = .view(nil) // In case song was activated
				case .select: songListState.selectMode = .select([])
			}
			guard !songsViewModel.songs.isEmpty else {
				reflectNoSongs()
				return
			}
			guard await moveRows(oldIdentifiers: oldRows, newIdentifiers: songsViewModel.rowIdentifiers()) else { return }
			
			tableView.reconfigureRows(at: tableView.allIndexPaths())
		}
	}
	private func reflectNoSongs() {
		isAnimatingReflectNoSongs += 1
		tableView.performBatchUpdates {
			tableView.deleteRows(at: tableView.allIndexPaths(), with: .middle)
		} completion: { _ in
			self.isAnimatingReflectNoSongs -= 1
			if self.isAnimatingReflectNoSongs == 0 {
				self.navigationController?.popViewController(animated: true)
			}
		}
	}
	private var isAnimatingReflectNoSongs = 0
	
	@objc private func confirmPlay(notification: Notification) {
		guard
			let chosenSongID = notification.object as? SongID,
			let chosenSongIndex: Int = songsViewModel.songs.firstIndex(where: {
				chosenSongID == $0.persistentID
			}),
			let popoverSource = tableView.cellForRow(at: IndexPath(row: SongsViewModel.prerowCount + chosenSongIndex, section: 0)),
			presentedViewController == nil // As of iOS 17.6 developer beta 1, if a `UIMenu` or SwiftUI `Menu` is open, `present` does nothing.
				// We could call `dismiss` and wait until completion to `present`, but that would be a worse user experience, because tapping outside the menu to close it could open this action sheet. So it’s better to do nothing here and simply let the tap close the menu.
				// Technically this is inconsistent because we still select and deselect items and open albums when dismissing a menu; and because toolbar buttons do nothing when dismissing a menu. But at least this prevents the most annoying behavior.
		else { return }
		
		songListState.selectMode = .view(chosenSongID) // The UI is clearer if we leave the row selected while the action sheet is onscreen. You must eventually deselect the row in every possible scenario after this moment.
		
		let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		actionSheet.popoverPresentationController?.sourceView = popoverSource
		actionSheet.addAction(
			UIAlertAction(title: InterfaceText.startPlaying, style: .default) { _ in
				Task {
					guard let chosenSong: Song = self.songsViewModel.songs.first(where: {
						chosenSongID == $0.persistentID
					}) else { return }
					await chosenSong.playAlbumStartingHere()
					
					self.songListState.selectMode = .view(nil)
				}
			}
			// I want to silence VoiceOver after you choose actions that start playback, but `UIAlertAction.accessibilityTraits = .startsMediaSession` doesn’t do it.)
		)
		actionSheet.addAction(
			UIAlertAction(title: InterfaceText.cancel, style: .cancel) { _ in
				self.songListState.selectMode = .view(nil)
			}
		)
		present(actionSheet, animated: true)
	}
	
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
