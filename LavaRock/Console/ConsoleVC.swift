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
	@IBOutlet private(set) final var reelTable: UITableView!
	@IBOutlet private final var futureChooser: FutureChooser!
	
	final var player: MPMusicPlayerController? { TapeDeck.shared.player }
	
	final override func viewDidLoad() {
		super.viewDidLoad()
		
		// Snatch dependencies, assuming `self` is the only instance of its type.
		Reel.table = reelTable
		
		reelTable.dataSource = self
		reelTable.delegate = self
		reelTable.backgroundColor = .secondarySystemBackground
		
		if let transportPanel = UIHostingController(rootView: TransportPanel().padding()).view {
			view.addSubview(transportPanel)
			transportPanel.translatesAutoresizingMaskIntoConstraints = false
			NSLayoutConstraint.activate([
				transportPanel.topAnchor.constraint(equalTo: futureChooser.bottomAnchor, constant: 4),
				transportPanel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
				transportPanel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
				transportPanel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
			])
		}
		
		beginReflectingPlaybackState()
		
		NotificationCenter.default.addObserverOnce(
			self,
			selector: #selector(beginReflectingNowPlayingItem_console),
			name: .LRUserRespondedToAllowAccessToMediaLibrary,
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
	
	@objc
	private func beginReflectingNowPlayingItem_console() {
		if MPMediaLibrary.authorizationStatus() == .authorized {
			NotificationCenter.default.addObserverOnce(
				self,
				selector: #selector(reflectPlayhead),
				name: .MPMusicPlayerControllerNowPlayingItemDidChange,
				object: player)
		}
	}
	
	static func rowContainsPlayhead(at indexPath: IndexPath) -> Bool {
		guard let player = TapeDeck.shared.player else {
			return false
		}
		return player.indexOfNowPlayingItem == indexPath.row
	}
}
