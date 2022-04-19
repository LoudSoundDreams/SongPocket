//
//  ConsoleVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2022-03-27.
//

import UIKit

extension ConsoleVC: UITableViewDataSource {
	private enum RowCase: CaseIterable {
		case song
		
		init(rowIndex: Int) {
			switch rowIndex {
			default:
				self = .song
			}
		}
	}
	
	final func tableView(
		_ tableView: UITableView,
		numberOfRowsInSection section: Int
	) -> Int {
		return Reel.mediaItems.count + (RowCase.allCases.count - 1)
	}
	
	final func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		switch RowCase(rowIndex: indexPath.row) {
		case .song:
			break
		}
		
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: "Song in Queue",
			for: indexPath) as? SongInQueueCell
		else { return UITableViewCell() }
		
		cell.configure(
			with: Reel.mediaItems[indexPath.row] as SongMetadatum)
		cell.indicateNowPlaying(
			containsPlayhead: Self.rowContainsPlayhead(at: indexPath))
		
		return cell
	}
}
extension ConsoleVC: UITableViewDelegate {
	final func tableView(
		_ tableView: UITableView,
		willSelectRowAt indexPath: IndexPath
	) -> IndexPath? {
		switch RowCase(rowIndex: indexPath.row) {
		case .song:
			return indexPath
		}
	}
	
	final func tableView(
		_ tableView: UITableView,
		didSelectRowAt indexPath: IndexPath
	) {
		tableView.deselectRow(at: indexPath, animated: true)
	}
}
