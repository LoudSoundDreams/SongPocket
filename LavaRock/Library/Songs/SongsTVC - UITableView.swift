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
		
		return viewModel.numberOfPresections + viewModel.groups.count
	}
	
	override func tableView(
		_ tableView: UITableView,
		numberOfRowsInSection section: Int
	) -> Int {
		return viewModel.numberOfRows(forSection: section)
	}
	
	// MARK: - Headers
	
	override func tableView(
		_ tableView: UITableView,
		titleForHeaderInSection section: Int
	) -> String? {
		if Enabling.multialbum {
			return (viewModel as? SongsViewModel)?
				.album(forSection: section)
				.representativeTitleFormattedOrPlaceholder()
		} else {
			return nil
		}
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
		let album = songsViewModel.album(forSection: indexPath.section)
		
		let rowCase = songsViewModel.rowCase(for: indexPath)
		switch rowCase {
		case .prerow(let prerow):
			switch prerow {
			case .coverArt:
				guard let cell = tableView.dequeueReusableCell(
					withIdentifier: "Cover Art",
					for: indexPath) as? CoverArtCell
				else { return UITableViewCell() }
				
				cell.album = album
				
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
				let album = songsViewModel.album(forSection: indexPath.section)
				return album.representativeSongMetadatum()
			}(),
			spacerTrackNumberText: (songsViewModel.group(forSection: indexPath.section) as? SongsGroup)?.spacerTrackNumberText,
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
