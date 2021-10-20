//
//  PlayerVC.swift
//  LavaRock
//
//  Created by h on 2021-10-19.
//

import UIKit
import MediaPlayer

final class PlayerVC: UIViewController {
	
	// Controls
	@IBOutlet private var playPauseButton: UIButton!
	
	private var sharedPlayer: MPMusicPlayerController? { PlayerManager.player }
	
	final override func viewDidLoad() {
		super.viewDidLoad()
		
		configurePlayPauseButton()
	}
	
	private lazy var playAction = UIAction(
//		image: UIImage(systemName: "play.fill")
	) { _ in
		self.sharedPlayer?.play()
		self.configurePlayPauseButton()
	}
	
	private lazy var pauseAction = UIAction(
//		image: UIImage(systemName: "pause.fill")
	) { _ in
		self.sharedPlayer?.pause()
		self.configurePlayPauseButton()
	}
	
	private func configurePlayPauseButton() {
		if sharedPlayer?.playbackState == .playing {
			
			
			playPauseButton.removeAction(playAction, for: .touchUpInside)
			
			
			playPauseButton.addAction(pauseAction, for: .touchUpInside)
			
			
			playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
		} else {
			
			
			playPauseButton.removeAction(pauseAction, for: .touchUpInside)
			
			
			playPauseButton.addAction(playAction, for: .touchUpInside)
			
			
			playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
		}
	}
	
	@IBAction func openMusic(_ sender: UIBarButtonItem) {
		URL.music?.open()
	}
	
	@IBAction func clearRecents(_ sender: UIBarButtonItem) {
		
		
	}
	
}
