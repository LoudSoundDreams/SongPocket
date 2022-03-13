//
//  Player - Views.swift
//  LavaRock
//
//  Created by h on 2022-03-13.
//

import UIKit
import MediaPlayer

final class ThenModeCell: UITableViewCell {
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
			beginReflectingPlaybackState()
		}}
	}
}

// TO DO: We don’t actually want to reflect playback state; we want to reflect whether the player is available, and if so, its repeat mode.
extension ThenModeCell: PlayerReflecting {
	final func reflectPlaybackState() {
		guard let player = player else {
			(0 ..< segmentedControl.numberOfSegments).forEach { indexOfSegment in
				segmentedControl.setEnabled(false, forSegmentAt: indexOfSegment)
			}
			segmentedControl.selectedSegmentIndex = 1
			return
		}
		(0 ..< segmentedControl.numberOfSegments).forEach { indexOfSegment in
			segmentedControl.setEnabled(true, forSegmentAt: indexOfSegment)
		}
		segmentedControl.selectedSegmentIndex = {
			if player.repeatMode == .one {
				return 0
			} else {
				return 1
			}}()
	}
}

enum LastMode {
	case repeatAll
	case stop
	
	static var current: Self = .stop
}

final class LastModeCell: UITableViewCell {
	@IBOutlet var segmentedControl: UISegmentedControl!
	
}
