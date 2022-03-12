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
		
		SongQueue.tableView = queueTable
		
		beginReflectingPlaybackState()
		
		navigationController?.setToolbarHidden(false, animated: false)
		toolbarItems = playbackToolbarButtons
	}
}

extension PlayerVC: PlayerReflecting {
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
		return SongQueue.songs.count
	}
	
	final func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Song in Queue", for: indexPath)
		
		var content = UIListContentConfiguration.cell()
		let metadatum = SongQueue.songs[indexPath.row].metadatum()
		content.image = metadatum?.artworkImage(
			at: CGSize(width: 5, height: 5))
		content.text = metadatum?.titleOnDisk
		content.secondaryText = metadatum?.artistOnDisk
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
