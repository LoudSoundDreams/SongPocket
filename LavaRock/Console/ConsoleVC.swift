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
		
		let hostingController = UIHostingController(
			rootView: TransportPanel()
				.padding()
		)
		if let transportPanel = hostingController.view {
			view.addSubview(transportPanel, activating: [
				transportPanel.topAnchor.constraint(equalTo: reelTable.bottomAnchor),
				transportPanel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
				transportPanel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
				transportPanel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
			])
		}
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
