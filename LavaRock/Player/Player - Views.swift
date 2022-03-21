//
//  Player - Views.swift
//  LavaRock
//
//  Created by h on 2022-03-13.
//

import UIKit
import MediaPlayer

private enum NextMode: Int {
	case repeatOne
	case continueQueue
	
	static var current: Self = .continueQueue
}

private enum LastMode: Int {
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
						NextMode.current = .repeatOne
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
						NextMode.current = .continueQueue
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
		segmentedControl.disable()
		segmentedControl.selectedSegmentIndex = NextMode.continueQueue.rawValue
		
		Task { await MainActor.run {
			reflectPlaybackStateFromNowOn()
		}}
	}
}

extension NextModeCell: PlayerReflecting {
	final func reflectPlaybackState() {
		guard
			let player = player,
			!SongQueue.contents.isEmpty
		else {
			segmentedControl.disable()
			segmentedControl.selectedSegmentIndex = NextMode.continueQueue.rawValue
			return
		}
		segmentedControl.enable()
		segmentedControl.selectedSegmentIndex = {
			if player.repeatMode == .one {
				return NextMode.repeatOne.rawValue
			} else {
				return NextMode.continueQueue.rawValue
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
						LastMode.current = .repeatAll
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
						LastMode.current = .stop
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
		segmentedControl.disable()
		segmentedControl.selectedSegmentIndex = LastMode.stop.rawValue
		
		Task { await MainActor.run {
			reflectPlaybackStateFromNowOn()
		}}
	}
}

extension LastModeCell: PlayerReflecting {
	func reflectPlaybackState() {
		guard
			let player = player,
			!SongQueue.contents.isEmpty
		else {
			segmentedControl.disable()
			segmentedControl.selectedSegmentIndex = LastMode.stop.rawValue
			return
		}
		switch player.repeatMode {
		case .default:
			fatalError("`MPMusicPlayerController.repeatMode == .default")
		case .one:
			segmentedControl.disable()
			segmentedControl.selectedSegmentIndex = LastMode.current.rawValue
		case .all:
			segmentedControl.enable()
			segmentedControl.selectedSegmentIndex = LastMode.repeatAll.rawValue
		case .none:
			segmentedControl.enable()
			segmentedControl.selectedSegmentIndex = LastMode.stop.rawValue
		@unknown default:
			fatalError("Unknown value for `MPMusicPlayerController.repeatMode")
		}
	}
}
