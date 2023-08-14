//
//  SongsTVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit
import SwiftUI
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
		_ tableView: UITableView,
		numberOfRowsInSection section: Int
	) -> Int {
		let songsViewModel = viewModel as! SongsViewModel
		if songsViewModel.album == nil {
			return 0 // Without `prerowCount`
		} else {
			return songsViewModel.prerowCount() + songsViewModel.libraryGroup().items.count
		}
	}
	
	override func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		let songsViewModel = viewModel as! SongsViewModel
		let album = songsViewModel.libraryGroup().container as! Album
		
		switch songsViewModel.rowCase(for: indexPath) {
			case .prerow:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(withIdentifier: "Album Banner", for: indexPath)
				cell.selectionStyle = .none
				cell.contentConfiguration = UIHostingConfiguration {
					HStack {
						VStack(
							alignment: .leading,
							spacing: .eight * 3/4
						) {
							Text(album.titleFormatted()) // “Rubber Soul”
								.font_title2_bold()
							Text(album.albumArtistFormatted()) // “The Beatles”
								.foregroundStyle(.secondary)
								.font_caption2_bold()
						}
						Spacer()
					}
					.alignmentGuide_separatorTrailing()
					.padding(.bottom, .eight * 1/2)
				}
				return cell
			case .song:
				break
		}
		
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: "Song",
			for: indexPath) as? SongCell
		else { return UITableViewCell() }
		cell.configureWith(
			song: songsViewModel.itemNonNil(atRow: indexPath.row) as! Song,
			albumRepresentative: album.representativeSongInfo(),
			spacerTrackNumberText: (songsViewModel.libraryGroup() as! SongsGroup).trackNumberSpacer,
			songsTVC: Weak(self)
		)
		return cell
	}
	
	// MARK: - Selecting
	
	override func tableView(
		_ tableView: UITableView,
		didSelectRowAt indexPath: IndexPath
	) {
		if !isEditing {
			if
				let player = TapeDeck.shared.player,
				let selectedCell = tableView.cellForRow(at: indexPath)
			{
				// The UI is clearer if we leave the row selected while the action sheet is onscreen.
				// You must eventually deselect the row in every possible scenario after this moment.
				
				let startPlaying = UIAlertAction(
					title: LRString.startPlaying,
					style: .default
				) { [weak self] _ in
					guard let self else { return }
					
					let numberToSkip = indexPath.row - (viewModel as! SongsViewModel).prerowCount()
					player.playNow(mediaItems(), skipping: numberToSkip)
					
					tableView.deselectAllRows(animated: true)
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
		}
		
		super.tableView(tableView, didSelectRowAt: indexPath)
	}
}
