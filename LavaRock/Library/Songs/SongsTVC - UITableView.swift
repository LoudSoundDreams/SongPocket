//
//  SongsTVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit
import SwiftUI

extension SongsTVC {
	// MARK: - Numbers
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		setOrRemoveNoItemsBackground()
		
		return viewModel.groups.count
	}
	
	override func tableView(
		_ tableView: UITableView,
		numberOfRowsInSection section: Int
	) -> Int {
		return (viewModel as! SongsViewModel).numberOfRows()
	}
	
	// MARK: - Cells
	
	override func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		guard let songsViewModel = viewModel as? SongsViewModel
		else {
			return UITableViewCell()
		}
		let album = songsViewModel.album()
		
		let rowCase = songsViewModel.rowCase(for: indexPath)
		switch rowCase {
		case .prerow(let prerow):
			switch prerow {
			case .coverArt:
				guard let cell = tableView.dequeueReusableCell(
					withIdentifier: "Cover Art",
					for: indexPath) as? CoverArtCell
				else { return UITableViewCell() }
				
				cell.albumRepresentative = album.representativeSongMetadatum()
				
				let height = view.frame.height
				let topInset = view.safeAreaInsets.top
				let bottomInset = view.safeAreaInsets.bottom
				let safeHeight = height - topInset - bottomInset
				cell.configureArtwork(maxHeight: safeHeight)
				
				return cell
				
			case .albumInfo:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(
					withIdentifier: "Album Info",
					for: indexPath)
				
				cell.contentConfiguration = UIHostingConfiguration {
					AlbumInfoRow(
						albumTitle: viewModel.bigTitle(),
						album: album)
					.alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
						viewDimensions[.leading]
					}
					.alignmentGuide(.listRowSeparatorTrailing) { viewDimensions in
						viewDimensions[.trailing]
					}
				}
				cell.selectionStyle = .none // So that the user can’t even highlight the cell
				
				return cell
			}
		case .song:
			break
		}
		
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: "Song",
			for: indexPath) as? SongCell
		else { return UITableViewCell() }
		
		cell.configureWith(
			song: songsViewModel.songNonNil(at: indexPath),
			albumRepresentative: {
				let album = songsViewModel.album()
				return album.representativeSongMetadatum()
			}(),
			spacerTrackNumberText: (songsViewModel.libraryGroup() as? SongsGroup)?.spacerTrackNumberText,
			songsTVC: Weak(self)
		)
		
		return cell
	}
	
	// MARK: - Selecting
	
	override func tableView(
		_ tableView: UITableView,
		didSelectRowAt indexPath: IndexPath
	) {
		if isEditing {
		} else {
			if
				let song = viewModel.itemNonNil(at: indexPath) as? Song,
				let selectedCell = tableView.cellForRow(at: indexPath)
			{
				showSongActions(for: song, popoverAnchorView: selectedCell)
				// This leaves the row selected while the action sheet is onscreen, which I prefer.
				// You must eventually deselect the row in every possible branch from here.
			}
		}
		
		super.tableView(tableView, didSelectRowAt: indexPath)
	}
}
