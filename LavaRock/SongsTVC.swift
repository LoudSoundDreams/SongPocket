// 2020-05-04

import UIKit
import SwiftUI
import MusicKit

final class SongsTVCStatus: ObservableObject {
	@Published fileprivate(set) var isEditing = false
}
final class SongsTVC: LibraryTVC {
	private let tvcStatus = SongsTVCStatus()
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		tvcStatus.isEditing = editing
		navigationItem.setLeftBarButtonItems(editing ? [.flexibleSpace()]/*Removes “Back” button*/ : [], animated: animated)
	}
	
	private lazy var arrangeSongsButton = UIBarButtonItem(title: LRString.sort, image: UIImage(systemName: "arrow.up.arrow.down"))
	private lazy var floatSongsButton = UIBarButtonItem(title: LRString.moveToTop, image: UIImage(systemName: "arrow.up.to.line"), primaryAction: UIAction { [weak self] _ in self?.floatSelected() })
	private lazy var sinkSongsButton = UIBarButtonItem(title: LRString.moveToBottom, image: UIImage(systemName: "arrow.down.to.line"), primaryAction: UIAction { [weak self] _ in self?.sinkSelected() })
	override func viewDidLoad() {
		editingButtons = [editButtonItem, .flexibleSpace(), arrangeSongsButton, .flexibleSpace(), floatSongsButton, .flexibleSpace(), sinkSongsButton]
		super.viewDidLoad()
	}
	override func refreshEditingButtons() {
		super.refreshEditingButtons()
		arrangeSongsButton.isEnabled = allowsArrange()
		arrangeSongsButton.menu = createArrangeMenu()
		floatSongsButton.isEnabled = allowsFloatAndSink()
		sinkSongsButton.isEnabled = allowsFloatAndSink()
	}
	private func createArrangeMenu() -> UIMenu {
		let sections: [[ArrangeCommand]] = [
			[.song_track],
			[.random, .reverse],
		]
		let elementsGrouped: [[UIMenuElement]] = sections.reversed().map { section in
			section.reversed().map { command in
				return command.createMenuElement(enabled: {
					guard selectedOrAllIndices().count >= 2 else { return false }
					switch command {
						case .random, .reverse: return true
						case .album_recentlyAdded, .album_newest, .album_artist: return false
						case .song_track: return true
					}
				}()) { [weak self] in self?.arrangeSelectedOrAll(by: command) }
			}
		}
		let inlineSubmenus = elementsGrouped.map {
			return UIMenu(options: .displayInline, children: $0)
		}
		return UIMenu(children: inlineSubmenus)
	}
	private func floatSelected() {
		var allSongs = viewModel.items
		let unorderedIndices = tableView.selectedIndexPaths.map { $0.row - SongsViewModel.prerowCount }
		allSongs.move(fromOffsets: IndexSet(unorderedIndices), toOffset: 0)
		Database.renumber(allSongs)
		let newViewModel = viewModel.withRefreshedData()
		Task { let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel) }
	}
	private func sinkSelected() {
		var allSongs = viewModel.items
		let unorderedIndices = tableView.selectedIndexPaths.map { $0.row - SongsViewModel.prerowCount }
		allSongs.move(fromOffsets: IndexSet(unorderedIndices), toOffset: allSongs.count)
		Database.renumber(allSongs)
		let newViewModel = viewModel.withRefreshedData()
		Task { let _ = await setViewModelAndMoveAndDeselectRowsAndShouldContinue(newViewModel) }
	}
	
	// MARK: - Table view
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		if viewModel.items.isEmpty {
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
		if viewModel.items.isEmpty {
			return 0 // Without `prerowCount`
		} else {
			return SongsViewModel.prerowCount + viewModel.items.count
		}
	}
	
	override func tableView(
		_ tableView: UITableView, cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		let album = (viewModel.items.first as! Song).container!
		switch indexPath.row {
			case 0:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(withIdentifier: "Album Header", for: indexPath)
				cell.selectionStyle = .none // So the user can’t even highlight the cell
				cell.backgroundColor = .clear
				cell.contentConfiguration = UIHostingConfiguration {
					AlbumHeader(album: album)
				}.margins(.all, .zero)
				return cell
			default:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(withIdentifier: "Song", for: indexPath)
				let song = viewModel.items[indexPath.row - SongsViewModel.prerowCount] as! Song
				cell.backgroundColor = .clear
				cell.selectedBackgroundView = {
					let result = UIView()
					result.backgroundColor = .tintColor.withAlphaComponent(.oneHalf)
					return result
				}()
				cell.contentConfiguration = UIHostingConfiguration {
					SongRow(song: song, album: album, tvcStatus: tvcStatus)
				}.margins(.all, .zero)
				return cell
		}
	}
	
	override func tableView(
		_ tableView: UITableView, willSelectRowAt indexPath: IndexPath
	) -> IndexPath? {
		guard indexPath.row >= SongsViewModel.prerowCount else { return nil }
		return indexPath
	}
	override func tableView(
		_ tableView: UITableView, didSelectRowAt indexPath: IndexPath
	) {
		if
			!isEditing,
			let selectedCell = tableView.cellForRow(at: indexPath)
		{
			// The UI is clearer if we leave the row selected while the action sheet is onscreen.
			// You must eventually deselect the row in every possible scenario after this moment.
			
			let song = viewModel.items[indexPath.row - SongsViewModel.prerowCount] as! Song
			let startPlaying = UIAlertAction(title: LRString.startPlaying, style: .default) { _ in
				Task {
					await song.playAlbumStartingHere()
					
					tableView.deselectAllRows(animated: true)
				}
			}
			// I want to silence VoiceOver after you choose actions that start playback, but `UIAlertAction.accessibilityTraits = .startsMediaSession` doesn’t do it.)
			
			let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
			actionSheet.popoverPresentationController?.sourceView = selectedCell
			actionSheet.addAction(startPlaying)
			actionSheet.addAction(
				UIAlertAction(title: LRString.cancel, style: .cancel) { [weak self] _ in
					self?.tableView.deselectAllRows(animated: true)
				}
			)
			present(actionSheet, animated: true)
		}
		
		super.tableView(tableView, didSelectRowAt: indexPath)
	}
	
	override func tableView(
		_ tableView: UITableView, canEditRowAt indexPath: IndexPath
	) -> Bool {
		return indexPath.row >= SongsViewModel.prerowCount
	}
	override func tableView(
		_ tableView: UITableView,
		targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
		toProposedIndexPath proposedDestinationIndexPath: IndexPath
	) -> IndexPath {
		if proposedDestinationIndexPath.row < SongsViewModel.prerowCount {
			return IndexPath(row: SongsViewModel.prerowCount, section: proposedDestinationIndexPath.section)
		}
		return proposedDestinationIndexPath
	}
}
