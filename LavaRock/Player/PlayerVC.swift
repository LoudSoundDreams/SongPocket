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
	@IBOutlet private var futureModeChooser: FutureModeChooser!
	
	final override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = .red.translucent() // TO DO: Delete
		
		queueTable.dataSource = self
		queueTable.delegate = self
		SongQueue.tableView = queueTable
		
		reflectPlaybackStateFromNowOn()
		
		navigationController?.setToolbarHidden(false, animated: false)
		toolbarItems = playbackToolbarButtons
		if let toolbar = navigationController?.toolbar {
			toolbar.scrollEdgeAppearance = toolbar.standardAppearance
		}
	}
}
extension PlayerVC: PlayerReflecting {
	func reflectPlaybackState() {
		freshenPlaybackToolbar()
	}
}
extension PlayerVC: PlaybackToolbarManaging {}
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
		
		guard var cell = tableView.dequeueReusableCell(
			withIdentifier: "Song in Queue",
			for: indexPath) as? SongInQueueCell
		else { return UITableViewCell() }
		
		cell.configure(with: SongQueue.contents[indexPath.row].metadatum())
		cell.indicateNowPlaying(
			isInPlayer: Int.random(in: 1...2) == 1,
			isPlaying: Int.random(in: 1...2) == 1)
		
		return cell
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
