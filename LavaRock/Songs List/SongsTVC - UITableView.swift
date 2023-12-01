//
//  SongsTVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit
import SwiftUI
import MusicKit
import OSLog

struct NoSongsView: View {
	var body: some View {
		Text(LRString.noSongs)
			.foregroundStyle(.secondary)
			.font(.title)
	}
}
extension SongsTVC {
	override func numberOfSections(in tableView: UITableView) -> Int {
		if viewModel.isEmpty() {
			tableView.backgroundView = UIHostingController(rootView: NoSongsView()).view
		} else {
			tableView.backgroundView = nil
		}
		
		return viewModel.groups.count
	}
	
	override func tableView(
		_ tableView: UITableView, numberOfRowsInSection section: Int
	) -> Int {
		let songsViewModel = viewModel as! SongsViewModel
		if songsViewModel.album == nil {
			return 0 // Without `prerowCount`
		} else {
			return songsViewModel.prerowCount() + songsViewModel.libraryGroup().items.count
		}
	}
	
	override func tableView(
		_ tableView: UITableView, cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		let songsViewModel = viewModel as! SongsViewModel
		let album = songsViewModel.libraryGroup().container as! Album
		
		switch songsViewModel.rowCase(for: indexPath) {
			case .prerow:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(withIdentifier: "Album Header", for: indexPath)
				cell.selectionStyle = .none // So the user can’t even highlight the cell
				cell.backgroundColors_configureForLibraryItem()
				cell.contentConfiguration = UIHostingConfiguration {
					AlbumHeader(
						album: album,
						trackNumberSpacer: (songsViewModel.libraryGroup() as! SongsGroup).trackNumberSpacer
					)
				}
				return cell
			case .song:
				guard let cell = tableView.dequeueReusableCell(
					withIdentifier: "Song",
					for: indexPath) as? SongCell
				else { return UITableViewCell() }
				cell.backgroundColors_configureForLibraryItem()
				cell.configureWith(
					song: songsViewModel.itemNonNil(atRow: indexPath.row) as! Song,
					albumRepresentative: album.representativeSongInfo(),
					spacerTrackNumberText: (songsViewModel.libraryGroup() as! SongsGroup).trackNumberSpacer,
					songsTVC: Weak(self),
					forBottomOfAlbum: indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1
				)
				return cell
		}
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
			
			let startPlaying = UIAlertAction(
				title: LRString.startPlaying,
				style: .default
			) { [weak self] _ in
				Task {
					guard
						let self,
						let player = SystemMusicPlayer.sharedIfAuthorized
					else { return }
					
					let allMusicItems: [MusicKit.Song] = await {
						var result: [MusicKit.Song] = []
						let allIDs = self.viewModel.libraryGroup().items.map {
							let song = $0 as! Song
							return MusicItemID(String(song.persistentID))
						}
						for id in allIDs {
							guard let musicItem = await MusicLibraryRequest.song(with: id) else { continue }
							result.append(musicItem)
						}
						return result
					}()
					let rowSong = (self.viewModel as! SongsViewModel).itemNonNil(atRow: indexPath.row) as! Song
					let rowMusicItem = await MusicLibraryRequest.song(with: MusicItemID(String(rowSong.persistentID)))
					
					guard let rowMusicItem else { return }
					
					player.queue = SystemMusicPlayer.Queue(for: allMusicItems, startingAt: rowMusicItem)
					try? await player.play()
					
					// As of iOS 17.2 beta, if setting the queue effectively did nothing, you must do these after calling `play`, not before.
					player.state.repeatMode = MusicPlayer.RepeatMode.none
					player.state.shuffleMode = .off
					
					tableView.deselectAllRows(animated: true)
				}
			}
			// I want to silence VoiceOver after you choose actions that start playback, but `UIAlertAction.accessibilityTraits = .startsMediaSession` doesn’t do it.)
			
			let actionSheet = UIAlertController(
				title: nil,
				message: nil,
				preferredStyle: .actionSheet)
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
}
