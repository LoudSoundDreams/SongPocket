//
//  ConsoleVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2022-03-27.
//

import UIKit

extension ConsoleVC: UITableViewDataSource {
	func tableView(
		_ tableView: UITableView,
		numberOfRowsInSection section: Int
	) -> Int {
		return Reel.mediaItems.count
	}
	
	func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: "Song in Queue",
			for: indexPath) as? QueueCell
		else { return UITableViewCell() }
		
		cell.configure(with: Reel.mediaItems[indexPath.row])
		
		return cell
	}
}
