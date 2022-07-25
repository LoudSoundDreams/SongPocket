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
	@IBOutlet private(set) var reelTable: UITableView!
	@IBOutlet private var reelTableBottomToSafeArea: NSLayoutConstraint!
	
	var player: MPMusicPlayerController? { TapeDeck.shared.player }
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		navigationItem.leftBarButtonItem = UIBarButtonItem(
			title: LRString.clear,
			primaryAction: UIAction { _ in
//				Reel.setMediaItems([])
//				TapeDeck.shared.player?.setQueue(mediaItems: []) // As of iOS 15.5, this doesn’t do anything.
			})
		navigationItem.rightBarButtonItem = {
			let dismissButton = UIBarButtonItem(
				title: LRString.done,
				primaryAction: UIAction { [weak self] _ in
					self?.dismiss(animated: true)
				})
			dismissButton.style = .done
			return dismissButton
		}()
		
		// Snatch dependencies, assuming `self` is the only instance of this type.
		Reel.table = reelTable
		
		reelTable.dataSource = self
		reelTable.delegate = self
		
		let hostingController = UIHostingController(
			rootView: TransportPanel()
				.padding()
		)
		if let transportPanel = hostingController.view {
			NSLayoutConstraint.deactivate([
				reelTableBottomToSafeArea,
			])
			view.addSubview(transportPanel, activating: [
				transportPanel.topAnchor.constraint(equalTo: reelTable.bottomAnchor),
				transportPanel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
				transportPanel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
				transportPanel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
			])
		}
		
		TapeDeck.shared.addReflector(weakly: self)
	}
	
	static func rowContainsPlayhead(at indexPath: IndexPath) -> Bool {
		guard let player = TapeDeck.shared.player else {
			return false
		}
		return player.indexOfNowPlayingItem == indexPath.row
	}
}
