//
//  SongsTVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit

extension SongsTVC {
	// MARK: - Numbers
	
	// Identical to counterpart in `AlbumsTVC`.
	final override func numberOfSections(in tableView: UITableView) -> Int {
		setOrRemoveNoItemsBackground()
		
		return super.numberOfSections(in: tableView)
	}
	
	final override func tableView(
		_ tableView: UITableView,
		numberOfRowsInSection section: Int
	) -> Int {
		return viewModel.numberOfRows(for: SectionIndex(section))
	}
	
	// MARK: - Headers
	
	final override func tableView(
		_ tableView: UITableView,
		titleForHeaderInSection section: Int
	) -> String? {
		if Enabling.multialbum {
			return (viewModel as? SongsViewModel)?
				.album(for: SectionIndex(section))
				.titleFormattedOrPlaceholder()
		} else {
			return nil
		}
	}
	
	// MARK: - Cells
	
	final override func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		guard let songsViewModel = viewModel as? SongsViewModel else { return UITableViewCell() }
		let rowCase = songsViewModel.rowCase(for: indexPath)
		switch rowCase {
		case .prerow(let prerow):
			switch prerow {
			case .coverArt:
				guard let cell = tableView.dequeueReusableCell(
					withIdentifier: "Cover Art",
					for: indexPath) as? CoverArtCell
				else { return UITableViewCell() }
				let album = songsViewModel.album(for: indexPath.sectionIndex)
				cell.configure(with: album)
				return cell
			case .albumInfo:
				guard let cell = tableView.dequeueReusableCell(
					withIdentifier: "Album Info",
					for: indexPath) as? AlbumInfoCell
				else { return UITableViewCell() }
				let album = songsViewModel.album(for: indexPath.sectionIndex)
				cell.configure(with: album)
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
				let album = songsViewModel.album(for: indexPath.sectionIndex)
				return album.representativeSongMetadatum()
			}())
		
		return cell
	}
	
	// MARK: - Selecting
	
	final override func tableView(
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
