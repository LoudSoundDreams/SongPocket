//
//  PlayerVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2022-03-27.
//

import UIKit

extension PlayerVC: UITableViewDataSource {
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
		return SongQueue.contents.count + (RowCase.allCases.count - 1)
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
		
		cell.configure(with: song(at: indexPath).metadatum())
		cell.indicateNowPlaying(
			isInPlayer: Self.songInQueueIsInPlayer(at: indexPath))
		
		return cell
	}
	
	private func song(at indexPath: IndexPath) -> Song {
		return SongQueue.contents[indexPath.row]
	}
}
extension PlayerVC: UITableViewDelegate {
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
