//
//  Player - Views.swift
//  LavaRock
//
//  Created by h on 2022-03-13.
//

import UIKit
import MediaPlayer

enum NextMode {
	case repeatOne
	case continueQueue
	
	static var current: Self = .continueQueue
}

enum LastMode {
	case repeatAll
	case stop
	
	static var current: Self = .stop
}

final class NextModeCell: UITableViewCell {
	@IBOutlet var segmentedControl: UISegmentedControl!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		segmentedControl.removeAllSegments()
		segmentedControl.insertSegment(
			action: UIAction(
				image: {
					let image = UIImage(systemName: "repeat.1")
					image?.accessibilityLabel = "Repeat one" // L2DO
					return image
				}()) { _ in
					// ARC2DO
					Task { await MainActor.run {
						self.player?.repeatMode = .one
					}}
				},
			at: segmentedControl.numberOfSegments,
			animated: false)
		segmentedControl.insertSegment(
			action: UIAction(
				image: {
					let image = UIImage(systemName: "play.fill")
					image?.accessibilityLabel = "Continue" // L2DO
					return image
				}()) { _ in
					// ARC2DO
					Task { await MainActor.run {
						switch LastMode.current {
						case .repeatAll:
							self.player?.repeatMode = .all
						case .stop:
							self.player?.repeatMode = .none
						}
					}}
				},
			at: segmentedControl.numberOfSegments,
			animated: false)
		
		Task { await MainActor.run {
			reflectPlaybackStateFromNowOn()
		}}
	}
}

// TO DO: We don’t actually want to reflect playback state; we want to reflect whether the player is available, and if so, its repeat mode.
extension NextModeCell: PlayerReflecting {
	final func reflectPlaybackState() {
		guard let player = player else {
			segmentedControl.disable()
			segmentedControl.selectedSegmentIndex = 1
			return
		}
		segmentedControl.enable()
		segmentedControl.selectedSegmentIndex = {
			if player.repeatMode == .one {
				return 0
			} else {
				return 1
			}}()
	}
}

final class LastModeCell: UITableViewCell {
	@IBOutlet var segmentedControl: UISegmentedControl!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		segmentedControl.removeAllSegments()
		segmentedControl.insertSegment(
			action: UIAction(
				image: {
					let image = UIImage(systemName: "repeat")
					image?.accessibilityLabel = "Repeat all" // L2DO
					return image
				}()) { _ in
					// ARC2DO
					Task { await MainActor.run {
						self.player?.repeatMode = .all
					}}
				},
			at: segmentedControl.numberOfSegments,
			animated: false)
		segmentedControl.insertSegment(
			action: UIAction(
				image: {
					let image = UIImage(systemName: "stop.fill")
					image?.accessibilityLabel = "stop" // L2DO
					return image
				}()) { _ in
					// ARC2DO
					Task { await MainActor.run {
						switch NextMode.current {
						case .repeatOne:
							self.player?.repeatMode = .one
						case .continueQueue:
							self.player?.repeatMode = .none
						}
					}}
				},
			at: segmentedControl.numberOfSegments,
			animated: false)
		
		Task { await MainActor.run {
			reflectPlaybackStateFromNowOn()
		}}
	}
}

// TO DO: We don’t actually want to reflect playback state; we want to reflect whether the player is available, and if so, its repeat mode.
extension LastModeCell: PlayerReflecting {
	func reflectPlaybackState() {
		guard let player = player else {
			segmentedControl.disable()
			segmentedControl.selectedSegmentIndex = 1
			return
		}
		segmentedControl.enable()
		segmentedControl.selectedSegmentIndex = {
			if player.repeatMode == .all {
				return 0
			} else {
				return 1
			}}()
	}
}
