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
	// `TransportToolbarManaging`
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
		Reel.tableView = queueTable
		queueTable.backgroundColor = .quaternarySystemFill
		
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
			selector: #selector(reelDidChange),
			name: .LRReelDidChange,
			object: nil)
		
		beginObservingNowPlayingItemDidChange_console()
		
		toolbarItems = transportButtons
//		navigationController?.setToolbarHidden(false, animated: false)
		if let toolbar = navigationController?.toolbar {
			let appearance = toolbar.standardAppearance
			appearance.configureWithTransparentBackground()
			toolbar.standardAppearance = appearance
		}
	}
	@objc private func mediaLibraryAuthorizationStatusDidChange() {
		beginObservingNowPlayingItemDidChange_console()
	}
	@objc private func reelDidChange() {
		freshenTransportToolbar()
	}
	
	private func beginObservingNowPlayingItemDidChange_console() {
		if MPMediaLibrary.authorizationStatus() == .authorized {
			NotificationCenter.default.addObserverOnce(
				self,
				selector: #selector(nowPlayingItemDidChange),
				name: .MPMusicPlayerControllerNowPlayingItemDidChange,
				object: player)
		}
	}
	@objc private func nowPlayingItemDidChange() { freshenNowPlayingIndicatorsAndTransportToolbar_console() }
	
	static func rowContainsPlayhead(at indexPath: IndexPath) -> Bool {
		guard let player = TapeDeck.shared.player else {
			return false
		}
		return player.indexOfNowPlayingItem == indexPath.row
	}
}
