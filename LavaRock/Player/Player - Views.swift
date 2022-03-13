//
//  Player - Views.swift
//  LavaRock
//
//  Created by h on 2022-03-13.
//

import UIKit

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
					Task { await MainActor.run {
						Player.shared.player?.repeatMode = .one
					}}
				},
			at: segmentedControl.numberOfSegments,
			animated: false)
		segmentedControl.insertSegment(
			action: UIAction(
				image: {
					let image = UIImage(systemName: "pause.fill")
					image?.accessibilityLabel = "Pause" // L2DO
					return image
				}()) { _ in
					
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
					
				},
			at: segmentedControl.numberOfSegments,
			animated: false)
		Task { await MainActor.run {
			if let player = Player.shared.player {
				segmentedControl.selectedSegmentIndex = {
					if player.repeatMode == .one {
						return 0
					} else {
						return 2
					}}()
			}
		}}
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
