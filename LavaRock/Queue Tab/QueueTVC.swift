//
//  QueueTVC.swift
//  LavaRock
//
//  Created by h on 2020-09-14.
//

import UIKit
import CoreData
import MediaPlayer

final class QueueTVC: UITableViewController {
	
	// MARK: - Properties
	
	// "Constants"
	var playerController: MPMusicPlayerController? = nil//MPMusicPlayerController.systemMusicPlayer
	@IBOutlet var clearButton: UIBarButtonItem!
	@IBOutlet var goToPreviousSongButton: UIBarButtonItem!
	@IBOutlet var restartCurrentSongButton: UIBarButtonItem!
	@IBOutlet var goToNextSongButton: UIBarButtonItem!
	lazy var playButton = UIBarButtonItem(
		image: UIImage(systemName: "play.fill"),
		style: .plain,
		target: self,
		action: #selector(play))
	lazy var pauseButton = UIBarButtonItem(
		image: UIImage(systemName: "pause.fill"),
		style: .plain,
		target: self,
		action: #selector(pause))
	let cellReuseIdentifier = "Cell"
	let numberOfNonQueueEntryCells = 0
	
	// Variables
	
	
	// MARK: - Setup
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		beginObservingAndGeneratingNotifications()
		// load data
		setUpUI()
		
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		playerController = MPMusicPlayerController.systemMusicPlayer
    }
	
	// MARK: Setting Up UI
	
	private func setUpUI() {
		isEditing = true
		
		refreshButtons()
		
		tableView.separatorInsetReference = .fromAutomaticInsets
		tableView.separatorInset.left = 44
		tableView.tableFooterView = UIView()
	}
	
	// MARK: Setup Events
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		refreshButtons()
	}
	
	// MARK: Teardown
	
	deinit {
		endObservingAndGeneratingNotifications()
	}
	
	// MARK: - Events
	
	func refreshButtons() {
		var playbackButtons: [UIBarButtonItem] = [
			goToPreviousSongButton,
			UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
			restartCurrentSongButton,
			UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
			playButton,
			UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
			goToNextSongButton
		]
		if playerController?.playbackState == .playing {
			if let indexOfPlayButton = playbackButtons.firstIndex(where: { playbackButton in
				playbackButton == playButton
			}) {
				playbackButtons[indexOfPlayButton] = pauseButton
			}
		}
		setToolbarItems(playbackButtons, animated: false)
		
		
		clearButton.isEnabled = false//QueueController.shared.entries.count > 0
//		goToPreviousSongButton.isEnabled = QueueController.shared.entries.count > 0
//		restartCurrentSongButton.isEnabled = QueueController.shared.entries.count > 0
//		playButton.isEnabled = QueueController.shared.entries.count > 0
//		goToNextSongButton.isEnabled = QueueController.shared.entries.count > 0
		
	}
	
	// MARK: Controlling Playback
	
	@IBAction func restartCurrentSong(_ sender: UIBarButtonItem) {
		playerController?.skipToBeginning()
	}
	
	@objc private func play() {
		playerController?.prepareToPlay()
		playerController?.play()
		refreshButtons()
	}
	
	@objc private func pause() {
		playerController?.pause()
		refreshButtons()
	}
	
}
