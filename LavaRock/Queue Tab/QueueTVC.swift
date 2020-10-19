//
//  QueueTVC.swift
//  LavaRock
//
//  Created by h on 2020-09-14.
//

import UIKit
import CoreData
import MediaPlayer

final class QueueTVC:
	UITableViewController//,
//	PlaybackToolbarManager
{
	/*
	
	// MARK: - Properties
	
	// "Constants"
	let playbackController = PlaybackController.shared
	@IBOutlet var clearButton: UIBarButtonItem!
	lazy var goToPreviousSongButton = UIBarButtonItem(
		image: UIImage(systemName: "backward.end.fill"),
		style: .plain, target: self, action: #selector(goToPreviousSong))
	lazy var restartCurrentSongButton = UIBarButtonItem(
		image: UIImage(systemName: "arrow.counterclockwise.circle.fill"),
		style: .plain, target: self, action: #selector(restartCurrentSong))
	lazy var playButton = UIBarButtonItem(
		image: UIImage(systemName: "play.fill"),
		style: .plain, target: self, action: #selector(play))
	lazy var pauseButton = UIBarButtonItem(
		image: UIImage(systemName: "pause.fill"),
		style: .plain, target: self, action: #selector(pause))
	lazy var goToNextSongButton = UIBarButtonItem(
		image: UIImage(systemName: "forward.end.fill"),
		style: .plain, target: self, action: #selector(goToNextSong))
	let flexibleSpaceBarButtonItem = UIBarButtonItem(
		barButtonSystemItem: .flexibleSpace,
		target: nil, action: nil)
	let cellReuseIdentifier = "Cell"
	let numberOfNonQueueEntryCells = 0
	
	// Variables
	
	
	// MARK: - Setup
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
//		beginObservingAndGeneratingNotifications()
		// load data
		setUpUI()
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
	
//	deinit {
//		endObservingAndGeneratingNotifications()
//	}
	
	// MARK: - Events
	
	func refreshButtons() {
		refreshPlaybackToolbarButtons()
		
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			clearButton.isEnabled = false
			return
		}
		
		clearButton.isEnabled = false //
	}
	
	func setAndRefreshPlaybackToolbar() {
		var playbackButtons: [UIBarButtonItem] = [
			goToPreviousSongButton,
			flexibleSpaceBarButtonItem,
			restartCurrentSongButton,
			flexibleSpaceBarButtonItem,
			playButton,
			flexibleSpaceBarButtonItem,
			goToNextSongButton
		]
		if PlaybackController.shared.playerController?.playbackState == .playing {
			if let indexOfPlayButton = playbackButtons.firstIndex(where: { playbackButton in
				playbackButton == playButton
			}) {
				playbackButtons[indexOfPlayButton] = pauseButton
			}
		}
		toolbarItems = playbackButtons
		
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			goToPreviousSongButton.isEnabled = false
			restartCurrentSongButton.isEnabled = false
			playButton.isEnabled = false
			goToNextSongButton.isEnabled = false
			return
		}
		
		// enable and disable the other buttons
	}
	
	@objc func presentClearQueueOptions() {
		
	}
	
	// MARK: - Controlling Playback
	
	@objc func goToPreviousSong() {
		
	}
	
	@objc func restartCurrentSong() {
		PlaybackController.shared.restartCurrentSong()
	}
	
	@objc func play() {
		PlaybackController.shared.play()
		refreshButtons()
	}
	
	@objc func pause() {
		PlaybackController.shared.pause()
		refreshButtons()
	}
	
	@objc func goToNextSong() {
		
	}
	
	
	*/
}
