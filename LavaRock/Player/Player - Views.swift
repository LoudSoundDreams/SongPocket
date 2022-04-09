//
//  Player - Views.swift
//  LavaRock
//
//  Created by h on 2022-03-13.
//

import UIKit
import MediaPlayer

// Similar to `AlbumCell` and `SongCell`.
final class SongInQueueCell: UITableViewCell, CellTintingWhenSelected {
	// `NowPlayingIndicating`
	@IBOutlet var spacerSpeakerImageView: UIImageView!
	@IBOutlet var speakerImageView: UIImageView!
	
	@IBOutlet private var textStack: UIStackView!
	@IBOutlet private var titleLabel: UILabel!
	@IBOutlet private var artistLabel: UILabel!
	
	final override func awakeFromNib() {
		tintSelectedBackgroundView()
		
		backgroundColor = .clear
	}
	
	final func configure(with metadatum: SongMetadatum?) {
		titleLabel.text = metadatum?.titleOnDisk ?? SongMetadatumExtras.unknownTitlePlaceholder
		artistLabel.text = nil
		
		if artistLabel.text == nil {
			textStack.spacing = 0
		} else {
			textStack.spacing = 4
		}
	}
}
extension SongInQueueCell: NowPlayingIndicating {}

final class FutureModeChooser: UISegmentedControl {
	private enum FutureMode: Int, CaseIterable {
		case repeatOne
		case repeatAll
		case normal
		
		var uiImage: UIImage {
			switch self {
			case .repeatOne:
				return UIImage(systemName: "repeat.1")!
			case .repeatAll:
				return UIImage(systemName: "repeat")!
			case .normal:
				return UIImage(systemName: "play.fill")!
			}
		}
		
		func apply(to player: MPMusicPlayerController) {
			switch self {
			case .repeatOne:
				player.repeatMode = .one
			case .repeatAll:
				player.repeatMode = .all
			case .normal:
				player.repeatMode = .none
			}
		}
	}
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		removeAllSegments()
		FutureMode.allCases.forEach { futureMode in
			insertSegment(
				action: UIAction(
					image: futureMode.uiImage
				) { _ in
					// ARC2DO
					Task { await MainActor.run {
						if let player = self.player {
							futureMode.apply(to: player)
						}
					}}
				},
				at: numberOfSegments,
				animated: false)
		}
		disable()
		selectedSegmentIndex = FutureMode.normal.rawValue
		
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
