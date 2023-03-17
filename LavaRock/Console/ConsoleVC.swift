//
//  ConsoleVC.swift
//  LavaRock
//
//  Created by h on 2021-10-19.
//

import UIKit
import MediaPlayer
import SwiftUI

final class ConsoleVC: UIViewController {
	@IBOutlet private(set) var reelTable: UITableView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Snatch dependencies, assuming `self` is the only instance of this type.
		Reel.table = reelTable
		
		reelTable.dataSource = self
	}
}
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
