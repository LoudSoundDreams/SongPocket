//
//  Player - Views.swift
//  LavaRock
//
//  Created by h on 2022-03-13.
//

import UIKit
import MediaPlayer

private enum FutureMode: Int {
	case repeatOne
	case repeatAll
	case normal
}

final class FutureModeChooser: UISegmentedControl {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		removeAllSegments()
		insertSegment(
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
			at: numberOfSegments,
			animated: false)
		insertSegment(
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
			at: numberOfSegments,
			animated: false)
		insertSegment(
			action: UIAction(
				image: {
					let image = UIImage(systemName: "play.fill")
					image?.accessibilityLabel = "Repeat off" // L2DO
					return image
				}()) { _ in
					// ARC2DO
					Task { await MainActor.run {
						self.player?.repeatMode = .none
					}}
				},
			at: numberOfSegments,
			animated: false)
		disable()
		selectedSegmentIndex = FutureMode.normal.rawValue
		
		Task { await MainActor.run {
			reflectPlaybackStateFromNowOn()
		}}
	}
}
extension FutureModeChooser: PlayerReflecting {
	func reflectPlaybackState() {
		guard
			let player = player,
			!SongQueue.contents.isEmpty
		else {
			disable()
			selectedSegmentIndex = FutureMode.normal.rawValue
			return
		}
		enable()
		switch player.repeatMode {
		case .default:
			fatalError("`MPMusicPlayerController.repeatMode == .default")
		case .one:
			selectedSegmentIndex = FutureMode.repeatOne.rawValue
		case .all:
			selectedSegmentIndex = FutureMode.repeatAll.rawValue
		case .none:
			selectedSegmentIndex = FutureMode.normal.rawValue
		@unknown default:
			fatalError("Unknown value for `MPMusicPlayerController.repeatMode")
		}
	}
}
