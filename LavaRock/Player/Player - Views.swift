//
//  Player - Views.swift
//  LavaRock
//
//  Created by h on 2022-03-13.
//

import UIKit
import MediaPlayer

final class SongInQueueCell: UITableViewCell, CellTintingWhenSelected {
	// `NowPlayingIndicating`
	@IBOutlet var spacerSpeakerImageView: UIImageView!
	@IBOutlet var speakerImageView: UIImageView!
	
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var artistLabel: UILabel!
	
	final override func awakeFromNib() {
		tintSelectedBackgroundView()
	}
	
	final func configure(with metadatum: SongMetadatum?) {
		titleLabel.text = metadatum?.titleOnDisk ?? SongMetadatumExtras.unknownTitlePlaceholder
		artistLabel.text = metadatum?.artistOnDisk ?? "Unknown Artist" // L2DO
	}
}
extension SongInQueueCell: NowPlayingIndicating {}

final class FutureModeChooser: UISegmentedControl {
	private enum Position: Int {
		case repeatOne
		case repeatAll
		case normal
	}
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		removeAllSegments()
		insertSegment(
			action: UIAction(
				image: {
					let image = UIImage(systemName: "repeat.1")
					image?.accessibilityLabel = LocalizedString.repeat1
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
					image?.accessibilityLabel = LocalizedString.repeatAll
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
					image?.accessibilityLabel = LocalizedString.repeatOff
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
		selectedSegmentIndex = Position.normal.rawValue
		
		Task { await MainActor.run {
			beginReflectingPlaybackState()
		}}
	}
}
extension FutureModeChooser: PlayerReflecting {
	func playbackStateDidChange() {
		guard
			let player = player,
			!SongQueue.contents.isEmpty
		else {
			disable()
			selectedSegmentIndex = Position.normal.rawValue
			return
		}
		enable()
		switch player.repeatMode {
		case .default:
			fatalError("`MPMusicPlayerController.repeatMode == .default")
		case .one:
			selectedSegmentIndex = Position.repeatOne.rawValue
		case .all:
			selectedSegmentIndex = Position.repeatAll.rawValue
		case .none:
			selectedSegmentIndex = Position.normal.rawValue
		@unknown default:
			fatalError("Unknown value for `MPMusicPlayerController.repeatMode")
		}
	}
}
