//
//  PlayerVC.swift
//  LavaRock
//
//  Created by h on 2021-10-19.
//

import UIKit
import MediaPlayer

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
		
		queueTable.dataSource = self
		queueTable.delegate = self
		SongQueue.tableView = queueTable
		
		beginReflectingPlaybackState()
		
		NotificationCenter.default.addObserverOnce(
			self,
			selector: #selector(mediaLibraryAuthorizationStatusDidChange),
			name: .LRMediaLibraryAuthorizationStatusDidChange,
			object: nil)
		
		beginObservingNowPlayingItemDidChange_PVC()
		
		navigationController?.setToolbarHidden(false, animated: false)
		toolbarItems = playbackToolbarButtons
		if let toolbar = navigationController?.toolbar {
			toolbar.scrollEdgeAppearance = toolbar.standardAppearance
		}
	}
	@objc private func mediaLibraryAuthorizationStatusDidChange() {
		beginObservingNowPlayingItemDidChange_PVC()
	}
	
	private func beginObservingNowPlayingItemDidChange_PVC() {
		if MPMediaLibrary.authorizationStatus() == .authorized {
			NotificationCenter.default.addObserverOnce(
				self,
				selector: #selector(nowPlayingItemDidChange),
				name: .MPMusicPlayerControllerNowPlayingItemDidChange,
				object: player)
		}
	}
	@objc private func nowPlayingItemDidChange() { freshenNowPlayingIndicatorsAndPlaybackToolbar_PVC() }
	
	private func freshenNowPlayingIndicatorsAndPlaybackToolbar_PVC() {
		queueTable.indexPathsForVisibleRowsNonNil.forEach { visibleIndexPath in
			guard var cell = queueTable.cellForRow(
				at: visibleIndexPath) as? NowPlayingIndicating
			else { return }
			cell.indicateNowPlaying(isInPlayer: isInPlayer(visibleIndexPath))
		}
		
		freshenPlaybackToolbar()
	}
	
	private func isInPlayer(_ indexPath: IndexPath) -> Bool {
		guard let player = player else {
			return false
		}
		return player.indexOfNowPlayingItem == indexPath.row
	}
	
	private func song(at indexPath: IndexPath) -> Song {
		return SongQueue.contents[indexPath.row]
	}
}
extension PlayerVC: PlayerReflecting {
	func playbackStateDidChange() {
		freshenNowPlayingIndicatorsAndPlaybackToolbar_PVC()
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
		
		cell.configure(with: song(at: indexPath).metadatum())
		cell.indicateNowPlaying(isInPlayer: isInPlayer(indexPath))
		
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
