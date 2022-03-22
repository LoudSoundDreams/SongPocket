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
	@IBOutlet private var nextLabel: UILabel!
	@IBOutlet private var chooser: UISegmentedControl!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		chooser.removeAllSegments()
		chooser.insertSegment(
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
			at: chooser.numberOfSegments,
			animated: false)
		chooser.insertSegment(
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
			at: chooser.numberOfSegments,
			animated: false)
		disable()
		chooser.selectedSegmentIndex = NextMode.current.rawValue
		
		Task { await MainActor.run {
			reflectPlaybackStateFromNowOn()
		}}
	}
	
	private func disable() {
		nextLabel.textColor = .placeholderText
		chooser.disable()
	}
	
	private func enable() {
		nextLabel.textColor = .label
		chooser.enable()
	}
}
extension NextModeCell: PlayerReflecting {
	final func reflectPlaybackState() {
		guard
			let player = player,
			!SongQueue.contents.isEmpty
		else {
			disable()
			chooser.selectedSegmentIndex = NextMode.continueQueue.rawValue
			return
		}
		enable()
		chooser.selectedSegmentIndex = {
			if player.repeatMode == .one {
				return NextMode.repeatOne.rawValue
			} else {
				return NextMode.continueQueue.rawValue
			}}()
	}
}

final class LastModeCell: UITableViewCell {
	@IBOutlet private var lastLabel: UILabel!
	@IBOutlet private var chooser: UISegmentedControl!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		chooser.removeAllSegments()
		chooser.insertSegment(
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
			at: chooser.numberOfSegments,
			animated: false)
		chooser.insertSegment(
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
			at: chooser.numberOfSegments,
			animated: false)
		disable()
		chooser.selectedSegmentIndex = LastMode.current.rawValue
		
		Task { await MainActor.run {
			reflectPlaybackStateFromNowOn()
		}}
	}
	
	private func disable() {
		lastLabel.textColor = .placeholderText
		chooser.disable()
	}
	
	private func enable() {
		lastLabel.textColor = .label
		chooser.enable()
	}
}
extension LastModeCell: PlayerReflecting {
	final func reflectPlaybackState() {
		guard
			let player = player,
			!SongQueue.contents.isEmpty
		else {
			disable()
			chooser.selectedSegmentIndex = LastMode.stop.rawValue
			return
		}
		switch player.repeatMode {
		case .default:
			fatalError("`MPMusicPlayerController.repeatMode == .default")
		case .one:
			disable()
			chooser.selectedSegmentIndex = LastMode.current.rawValue
		case .all:
			enable()
			chooser.selectedSegmentIndex = LastMode.repeatAll.rawValue
		case .none:
			enable()
			chooser.selectedSegmentIndex = LastMode.stop.rawValue
		@unknown default:
			fatalError("Unknown value for `MPMusicPlayerController.repeatMode")
		}
	}
}

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
