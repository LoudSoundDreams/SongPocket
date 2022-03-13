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
		
		reflectPlaybackStateFromNowOn()
		
		navigationController?.setToolbarHidden(false, animated: false)
		toolbarItems = playbackToolbarButtons
		
		view.backgroundColor = .systemFill // TO DO: Delete
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
		case then
		case last
		case song
		
		init(rowIndex: Int) {
			switch rowIndex {
			case 0:
				self = .then
			case 1:
				self = .last
			default:
				self = .song
			}
		}
	}
	
	final func tableView(
		_ tableView: UITableView,
		numberOfRowsInSection section: Int
	) -> Int {
		return SongQueue.songs.count + (RowCase.allCases.count - 1)
	}
	
	final func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		switch RowCase(rowIndex: indexPath.row) {
		case .then:
			guard let cell = tableView.dequeueReusableCell(
				withIdentifier: "Then",
				for: indexPath) as? ThenModeCell
			else { return UITableViewCell() }
			
			return cell
		case .last:
			guard let cell = tableView.dequeueReusableCell(
				withIdentifier: "Last",
				for: indexPath) as? LastModeCell
			else { return UITableViewCell() }
			
			return cell
		case .song:
			break
		}
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "Song in Queue", for: indexPath)
		
		var content = UIListContentConfiguration.cell()
		let metadatum = SongQueue.songs[indexPath.row - 2].metadatum()
//		let metadatum = SongQueue.songs[indexPath.row].metadatum()
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
		willSelectRowAt indexPath: IndexPath
	) -> IndexPath? {
		switch RowCase(rowIndex: indexPath.row) {
		case .then:
			return nil
		case .last:
			return nil
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
