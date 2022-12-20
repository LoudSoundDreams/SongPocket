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
	
	func tableView(
		_ tableView: UITableView,
		numberOfRowsInSection section: Int
	) -> Int {
		return Reel.mediaItems.count + (RowCase.allCases.count - 1)
	}
	
	func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		switch RowCase(rowIndex: indexPath.row) {
		case .song:
			break
		}
		
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: "Song in Queue",
			for: indexPath) as? QueueCell
		else { return UITableViewCell() }
		
		cell.configure(with: Reel.mediaItems[indexPath.row])
		cell.reflectPlayhead(
			containsPlayhead: Self.rowContainsPlayhead(at: indexPath),
			rowContentAccessibilityLabel: cell.rowContentAccessibilityLabel)
		
		return cell
	}
}
extension ConsoleVC: UITableViewDelegate {
	func tableView(
		_ tableView: UITableView,
		willSelectRowAt indexPath: IndexPath
	) -> IndexPath? {
		switch RowCase(rowIndex: indexPath.row) {
		case .song:
			return indexPath
		}
	}
	
	func tableView(
		_ tableView: UITableView,
		didSelectRowAt indexPath: IndexPath
	) {
		tableView.deselectRow(at: indexPath, animated: true)
	}
}
