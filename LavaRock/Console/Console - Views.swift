//
//  Console - Views.swift
//  LavaRock
//
//  Created by h on 2022-03-13.
//

import UIKit
import MediaPlayer

// Similar to `AlbumCell` and `SongCell`.
final class SongInQueueCell: UITableViewCell {
	// `PlayheadReflectable`
	@IBOutlet var spacerSpeakerImageView: UIImageView!
	@IBOutlet var speakerImageView: UIImageView!
	
	@IBOutlet private var coverArtView: UIImageView!
	@IBOutlet private var textStack: UIStackView!
	@IBOutlet private var titleLabel: UILabel!
	@IBOutlet private var secondaryLabel: UILabel!
	
	final override func awakeFromNib() {
		tintSelectedBackgroundView()
		
		removeBackground()
		
		coverArtView.layer.cornerCurve = .continuous
		coverArtView.layer.cornerRadius = 3
	}
	
	final func configure(with metadatum: SongMetadatum) {
		coverArtView.image = metadatum.coverArt(
			at: CGSize(
				width: coverArtView.frame.width,
				height: coverArtView.frame.height))
		
		// Don’t let these be `nil`.
		titleLabel.text = { () -> String in
			if let songTitle = metadatum.titleOnDisk {
				return songTitle
			} else {
				return SongMetadatumPlaceholder.unknownTitle
			}
		}()
		secondaryLabel.text = { () -> String in
			if let albumTitle = metadatum.albumTitleOnDisk {
				return albumTitle
			} else {
				return Album.unknownTitlePlaceholder
			}
		}()
		
		// Update constraints
		if secondaryLabel.text == nil {
			textStack.spacing = 0
		} else {
			textStack.spacing = 4
		}
	}
	
	final override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.left = textStack.frame.minX
		separatorInset.right = directionalLayoutMargins.trailing
	}
}
extension SongInQueueCell:
	PlayheadReflectable,
	CellTintingWhenSelected,
	CellHavingTransparentBackground
{}

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
	
	private var player: MPMusicPlayerController? { TapeDeck.shared.player }
	
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
	func reflectPlaybackState() {
		guard
			let player = player,
			!Reel.mediaItems.isEmpty
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
