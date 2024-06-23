// 2020-05-04

import UIKit
import SwiftUI
import CoreData

@MainActor struct SongsViewModel {
	static let prerowCount = 1
	var songs: [Song] { didSet { Database.renumber(songs) } }
	func withRefreshedData() -> Self {
		// Get the `Album` from the first non-deleted `Song`.
		guard let album = songs.first(where: { nil != $0.container })?.container else {
			return Self(songs: [])
		}
		return Self(album: album)
	}
	func rowIdentifiers() -> [AnyHashable] {
		let itemRowIDs = songs.map { AnyHashable($0.objectID) }
		return [42] + itemRowIDs
	}
}
extension SongsViewModel {
	init(album: Album) { songs = album.songs(sorted: true) }
}

@Observable final class SongsTVCStatus {
	fileprivate(set) var isEditing = false
	var editingSongIndices: Set<Int> = [] // Should only contain elements if `isEditing`. This should be an optional set, but as of Xcode 15.4, the compiler can’t type-check that.
}

// MARK: - Table view controller

final class SongsTVC: LibraryTVC {
	var songsViewModel: SongsViewModel! = nil
	
	private let tvcStatus = SongsTVCStatus()
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		if editing {
			tvcStatus.isEditing = true
		} else {
			tvcStatus.isEditing = false
			tvcStatus.editingSongIndices = []
		}
		navigationItem.setLeftBarButtonItems(editing ? [.flexibleSpace()]/*Removes “Back” button*/ : [], animated: animated)
	}
	
	private lazy var arrangeButton = UIBarButtonItem(title: InterfaceText.sort, image: UIImage(systemName: "arrow.up.arrow.down"))
	private lazy var floatButton = UIBarButtonItem(title: InterfaceText.moveToTop, image: UIImage(systemName: "arrow.up.to.line"), primaryAction: UIAction { [weak self] _ in self?.float() })
	private lazy var sinkButton = UIBarButtonItem(title: InterfaceText.moveToBottom, image: UIImage(systemName: "arrow.down.to.line"), primaryAction: UIAction { [weak self] _ in self?.sink() })
	private lazy var promoteButton = UIBarButtonItem(title: InterfaceText.moveUp, image: UIImage(systemName: "chevron.up"), primaryAction: UIAction { [weak self] _ in self?.promote() })
	private lazy var demoteButton = UIBarButtonItem(title: InterfaceText.moveDown, image: UIImage(systemName: "chevron.down"), primaryAction: UIAction { [weak self] _ in self?.demote() })
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		editingButtons = [editButtonItem, .flexibleSpace(), arrangeButton, .flexibleSpace(), floatButton, .flexibleSpace(), promoteButton, .flexibleSpace(), demoteButton, .flexibleSpace(), sinkButton]
		arrangeButton.preferredMenuElementOrder = .fixed
		super.viewDidLoad()
		
		NotificationCenter.default.addObserverOnce(self, selector: #selector(activatedSong), name: SongRow.activatedSong, object: nil)
	}
	@objc private func activatedSong(notification: Notification) {
		guard
			let activated = notification.object as? Song,
			let songIndex = songsViewModel.songs.firstIndex(where: { song in
				activated.objectID == song.objectID
			})
		else { return }
		confirmPlay(IndexPath(row: SongsViewModel.prerowCount + songIndex, section: 0))
	}
	private func confirmPlay(_ activated: IndexPath) {
		guard let activatedCell = tableView.cellForRow(at: activated) else { return }
		
		tableView.selectRow(at: activated, animated: false, scrollPosition: .none)
		// The UI is clearer if we leave the row selected while the action sheet is onscreen.
		// You must eventually deselect the row in every possible scenario after this moment.
		
		let song = songsViewModel.songs[activated.row - SongsViewModel.prerowCount]
		let startPlaying = UIAlertAction(title: InterfaceText.startPlaying, style: .default) { _ in
			Task {
				await song.playAlbumStartingHere()
				
				self.tableView.deselectAllRows(animated: true)
			}
		}
		// I want to silence VoiceOver after you choose actions that start playback, but `UIAlertAction.accessibilityTraits = .startsMediaSession` doesn’t do it.)
		
		let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		actionSheet.popoverPresentationController?.sourceView = activatedCell
		actionSheet.addAction(startPlaying)
		actionSheet.addAction(
			UIAlertAction(title: InterfaceText.cancel, style: .cancel) { [weak self] _ in
				self?.tableView.deselectAllRows(animated: true)
			}
		)
		present(actionSheet, animated: true)
	}
	
	override func refreshLibraryItems() {
		Task {
			let oldRows = songsViewModel.rowIdentifiers()
			songsViewModel = songsViewModel.withRefreshedData()
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
		setEditing(false, animated: true)
	}
	private var isAnimatingReflectNoSongs = 0
	
	// MARK: - Editing
	
	override func refreshEditingButtons() {
		super.refreshEditingButtons()
		editButtonItem.isEnabled = !songsViewModel.songs.isEmpty
		arrangeButton.isEnabled = canArrange()
		arrangeButton.menu = newArrangeMenu()
		floatButton.isEnabled = !tableView.selectedIndexPaths.isEmpty
		sinkButton.isEnabled = !tableView.selectedIndexPaths.isEmpty
	}
	
	private func canArrange() -> Bool {
		let selected = tableView.selectedIndexPaths
		if selected.isEmpty { return true }
		return selected.map { $0.row }.sorted().isConsecutive()
	}
	private func newArrangeMenu() -> UIMenu {
		let sections: [[ArrangeCommand]] = [
			[.song_track],
			[.random, .reverse],
		]
		let elementsGrouped: [[UIMenuElement]] = sections.map { section in
			section.map { command in
				return command.newMenuElement(enabled: {
					guard selectedOrAllIndices().count >= 2 else { return false }
					switch command {
						case .random, .reverse: return true
						case .album_recentlyAdded, .album_newest, .album_artist: return false
						case .song_track: return true
					}
				}()) { [weak self] in self?.arrange(by: command) }
			}
		}
		let inlineSubmenus = elementsGrouped.map {
			return UIMenu(options: .displayInline, children: $0)
		}
		return UIMenu(children: inlineSubmenus)
	}
	private func arrange(by command: ArrangeCommand) {
		let oldRows = songsViewModel.rowIdentifiers()
		songsViewModel.songs = {
			let subjectedIndicesInOrder = selectedOrAllIndices().sorted()
			let toSort = subjectedIndicesInOrder.map { songsViewModel.songs[$0] }
			let sorted = command.apply(to: toSort) as! [Song]
			var result = songsViewModel.songs
			subjectedIndicesInOrder.indices.forEach { counter in
				let replaceAt = subjectedIndicesInOrder[counter]
				let newItem = sorted[counter]
				result[replaceAt] = newItem
			}
			return result
		}()
		Task { let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: songsViewModel.rowIdentifiers()) }
	}
	private func selectedOrAllIndices() -> [Int] {
		let selected = tableView.selectedIndexPaths
		guard !selected.isEmpty else { return songsViewModel.songs.indices.map { $0 } }
		return selected.map { $0.row - SongsViewModel.prerowCount }
	}
	
	private func float() {
		let oldRows = songsViewModel.rowIdentifiers()
		var newSongs = songsViewModel.songs
		let unorderedIndices = tableView.selectedIndexPaths.map { $0.row - SongsViewModel.prerowCount }
		newSongs.move(fromOffsets: IndexSet(unorderedIndices), toOffset: 0)
		Database.renumber(newSongs)
		songsViewModel.songs = newSongs
		Task { let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: songsViewModel.rowIdentifiers()) }
	}
	private func sink() {
		let oldRows = songsViewModel.rowIdentifiers()
		var newSongs = songsViewModel.songs
		let unorderedIndices = tableView.selectedIndexPaths.map { $0.row - SongsViewModel.prerowCount }
		newSongs.move(fromOffsets: IndexSet(unorderedIndices), toOffset: newSongs.count)
		Database.renumber(newSongs)
		songsViewModel.songs = newSongs
		Task { let _ = await moveRows(oldIdentifiers: oldRows, newIdentifiers: songsViewModel.rowIdentifiers()) }
	}
	
	private func promote() {
		let indicesSorted = Array(tvcStatus.editingSongIndices).sorted()
		guard let frontmostIndex = indicesSorted.first else { return }
		let oldRows = songsViewModel.rowIdentifiers()
		var newSongs = songsViewModel.songs
		let targetIndex = indicesSorted.isConsecutive() ? max(0, frontmostIndex - 1) : frontmostIndex
		
		tvcStatus.editingSongIndices = Set(targetIndex ... (targetIndex + indicesSorted.count - 1))
		newSongs.move(fromOffsets: IndexSet(indicesSorted), toOffset: targetIndex)
		Database.renumber(newSongs)
		songsViewModel.songs = newSongs
		Task {
			let _ = await moveRows(
				oldIdentifiers: oldRows,
				newIdentifiers: songsViewModel.rowIdentifiers(),
				runningBeforeContinuation: {
					self.tableView.scrollToRow(at: IndexPath(row: SongsViewModel.prerowCount + targetIndex, section: 0), at: .middle, animated: true)
				})
		}
	}
	func demote() {
		let indicesSorted = Array(tvcStatus.editingSongIndices).sorted()
		guard let backmostIndex = indicesSorted.last else { return }
		let oldRows = songsViewModel.rowIdentifiers()
		var newSongs = songsViewModel.songs
		let targetIndex = indicesSorted.isConsecutive() ? min(songsViewModel.songs.count - 1, backmostIndex + 1) : backmostIndex
		
		tvcStatus.editingSongIndices = Set((targetIndex - indicesSorted.count + 1) ... targetIndex)
		newSongs.move(fromOffsets: IndexSet(indicesSorted), toOffset: targetIndex + 1)
		Database.renumber(newSongs)
		songsViewModel.songs = newSongs
		Task {
			let _ = await moveRows(
				oldIdentifiers: oldRows,
				newIdentifiers: songsViewModel.rowIdentifiers(),
				runningBeforeContinuation: {
					self.tableView.scrollToRow(at: IndexPath(row: SongsViewModel.prerowCount + targetIndex, section: 0), at: .middle, animated: true)
				})
		}
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
	override func tableView(
		_ tableView: UITableView, numberOfRowsInSection section: Int
	) -> Int {
		if songsViewModel.songs.isEmpty {
			return 0 // Without `prerowCount`
		} else {
			return SongsViewModel.prerowCount + songsViewModel.songs.count
		}
	}
	
	override func tableView(
		_ tableView: UITableView, cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		let album = songsViewModel.songs.first!.container!
		switch indexPath.row {
			case 0:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(withIdentifier: "Album Header", for: indexPath)
				cell.selectionStyle = .none // So the user can’t even highlight the cell
				cell.backgroundColor = .clear
				cell.contentConfiguration = UIHostingConfiguration {
					AlbumHeader(albumPersistentID: album.albumPersistentID)
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
					SongRow(song: song, albumPersistentID: album.albumPersistentID, songsTVCStatus: tvcStatus)
				}.margins(.all, .zero)
				return cell
		}
	}
	
	override func tableView(
		_ tableView: UITableView, willSelectRowAt indexPath: IndexPath
	) -> IndexPath? {
		return nil
	}
	
	override func tableView(
		_ tableView: UITableView, canEditRowAt indexPath: IndexPath
	) -> Bool {
		// As of iOS 17.6 developer beta 1, returning `false` removes selection circles even if `tableView.allowsMultipleSelectionDuringEditing`, and removes reorder controls even if you implement `moveRowAt`.
		return false
	}
	override func tableView( // TO DO: Delete
		_ tableView: UITableView,
		targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
		toProposedIndexPath proposedDestinationIndexPath: IndexPath
	) -> IndexPath {
		if proposedDestinationIndexPath.row < SongsViewModel.prerowCount {
			return IndexPath(row: SongsViewModel.prerowCount, section: proposedDestinationIndexPath.section)
		}
		return proposedDestinationIndexPath
	}
	override func tableView( // TO DO: Delete
		_ tableView: UITableView,
		moveRowAt source: IndexPath,
		to destination: IndexPath
	) {
		let fromIndex = source.row - SongsViewModel.prerowCount
		let toIndex = destination.row - SongsViewModel.prerowCount
		
		var newItems = songsViewModel.songs
		let passenger = newItems.remove(at: fromIndex)
		newItems.insert(passenger, at: toIndex)
		songsViewModel.songs = newItems
		
		refreshEditingButtons()
	}
}
