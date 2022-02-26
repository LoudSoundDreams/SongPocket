//
//  PlayerVC.swift
//  LavaRock
//
//  Created by h on 2021-10-19.
//

import UIKit

final class PlayerVC: UIViewController {
	// `PlaybackToolbarManaging`
	private(set) lazy var previousSongButton = makePreviousSongButton()
	private(set) lazy var skipBackwardButton = makeSkipBackwardButton()
	private(set) lazy var playPauseButton = UIBarButtonItem()
	private(set) lazy var skipForwardButton = makeSkipForwardButton()
	private(set) lazy var nextSongButton = makeNextSongButton()
	
	@IBOutlet private var queueTable: UITableView!
	
	final override func viewDidLoad() {
		super.viewDidLoad()
		
		queueTable.dataSource = self
		queueTable.delegate = self
		
		beginReflectingPlaybackState()
		
		toolbarItems = playbackToolbarButtons
	}
	
	deinit {
		DispatchQueue.main.sync {
			endReflectingPlaybackState()
		}
	}
}

extension PlayerVC: PlaybackStateReflecting {
	func reflectPlaybackState() {
		freshenPlaybackToolbar()
	}
}

extension PlayerVC: PlaybackToolbarManaging {}

extension PlayerVC: UITableViewDataSource {
	final func tableView(
		_ tableView: UITableView,
		numberOfRowsInSection section: Int
	) -> Int {
		return 10
	}
	
	final func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		switch indexPath.row {
		case 5:
			return tableView.dequeueReusableCell(withIdentifier: "Then", for: indexPath)
		case 9:
			return tableView.dequeueReusableCell(withIdentifier: "Last", for: indexPath)
		default:
			break
		}
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "Song in Queue", for: indexPath)
		
		var content = UIListContentConfiguration.cell()
		content.image = UIImage(named: "AppIcon")
		content.text = "Song Title"
		content.secondaryText = "Artist Name"
		content.secondaryTextProperties.color = .secondaryLabel
		cell.contentConfiguration = content
		
		return cell
	}
}

extension PlayerVC: UITableViewDelegate {
	final func tableView(
		_ tableView: UITableView,
		didSelectRowAt indexPath: IndexPath
	) {
		tableView.deselectRow(at: indexPath, animated: true)
	}
}
