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
	private(set) lazy var jumpBackwardButton = makeJumpBackwardButton()
	private(set) lazy var playPauseButton = UIBarButtonItem()
	private(set) lazy var jumpForwardButton = makeJumpForwardButton()
	private(set) lazy var nextSongButton = makeNextSongButton()
	private(set) lazy var moreButton = makeMoreButton()
	
	@IBOutlet private(set) final var queueTable: UITableView!
	@IBOutlet private final var futureModeChooser: FutureModeChooser!
	
	final var player: MPMusicPlayerController? { TapeDeck.shared.player }
	
	final override func viewDidLoad() {
		super.viewDidLoad()
		
		queueTable.dataSource = self
		queueTable.delegate = self
		Reel.tableView = queueTable
		queueTable.backgroundColor = .secondarySystemBackground
		
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
			name: .LRUserRespondedToAllowAccessToMediaLibrary,
			object: nil)
		NotificationCenter.default.addObserverOnce(
			self,
			selector: #selector(reelDidChange),
			name: .LRModifiedReel,
			object: nil)
		
		beginReflectingNowPlayingItem_console()
		
		navigationItem.rightBarButtonItem = {
			let dismissButton = UIBarButtonItem(
				title: LocalizedString.done,
				primaryAction: UIAction { [weak self] _ in
					self?.dismiss(animated: true)
				})
			dismissButton.style = .done
			return dismissButton
		}()
	}
	@objc private func mediaLibraryAuthorizationStatusDidChange() {
		beginReflectingNowPlayingItem_console()
	}
	@objc private func reelDidChange() {
		freshenTransportToolbar()
	}
	
	private func beginReflectingNowPlayingItem_console() {
		if MPMediaLibrary.authorizationStatus() == .authorized {
			NotificationCenter.default.addObserverOnce(
				self,
				selector: #selector(reflectNowPlayingItem),
				name: .MPMusicPlayerControllerNowPlayingItemDidChange,
				object: player)
		}
	}
	@objc private func reflectNowPlayingItem() { reflectPlayheadAndFreshenTransportToolbar_console() }
	
	static func rowContainsPlayhead(at indexPath: IndexPath) -> Bool {
		guard let player = TapeDeck.shared.player else {
			return false
		}
		return player.indexOfNowPlayingItem == indexPath.row
	}
}
