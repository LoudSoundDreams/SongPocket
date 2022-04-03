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
	private(set) lazy var rewindButton = makeRewindButton()
	private(set) lazy var skipBackwardButton = makeSkipBackwardButton()
	private(set) lazy var playPauseButton = UIBarButtonItem()
	private(set) lazy var skipForwardButton = makeSkipForwardButton()
	private(set) lazy var nextSongButton = makeNextSongButton()
	
	@IBOutlet final var queueTable: UITableView!
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
		NotificationCenter.default.addObserverOnce(
			self,
			selector: #selector(songQueueDidChange),
			name: .LRSongQueueDidChange,
			object: nil)
		
		beginObservingNowPlayingItemDidChange_PVC()
		
		toolbarItems = playbackToolbarButtons
		navigationController?.setToolbarHidden(false, animated: false)
		if let toolbar = navigationController?.toolbar {
			let appearance = toolbar.standardAppearance
			appearance.configureWithTransparentBackground()
			toolbar.standardAppearance = appearance
		}
	}
	@objc private func mediaLibraryAuthorizationStatusDidChange() {
		beginObservingNowPlayingItemDidChange_PVC()
	}
	@objc private func songQueueDidChange() {
		freshenPlaybackToolbar()
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
	
	final func songInQueueIsInPlayer(at indexPath: IndexPath) -> Bool {
		guard let player = player else {
			return false
		}
		return player.indexOfNowPlayingItem == indexPath.row
	}
}
