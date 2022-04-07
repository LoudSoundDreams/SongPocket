//
//  PlayerVC.swift
//  LavaRock
//
//  Created by h on 2021-10-19.
//

import UIKit
import MediaPlayer
import SwiftUI

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
		queueTable.backgroundColor = .tertiarySystemFill // As of iOS 15.4, this is closest to the background of a segmented control. The next-closest is `.secondarySystemBackground`.
		
		if let transportPanel = UIHostingController(rootView: TransportPanel().padding()).view {
			view.addSubview(transportPanel)
			transportPanel.translatesAutoresizingMaskIntoConstraints = false
			NSLayoutConstraint.activate([
				transportPanel.topAnchor.constraint(equalTo: futureModeChooser.bottomAnchor, constant: 4),
				transportPanel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
				transportPanel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
				transportPanel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
			])
		}
		
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
//		navigationController?.setToolbarHidden(false, animated: false)
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
