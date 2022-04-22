//
//  Songs - Views.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit
import MediaPlayer
import OSLog

final class CoverArtCell: UITableViewCell {
	@IBOutlet private var coverArtView: UIImageView!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		coverArtView.accessibilityIgnoresInvertColors = true
		accessibilityLabel = LocalizedString.albumArtwork
		accessibilityUserInputLabels = [""]
		accessibilityTraits.formUnion(.image)
	}
	
	final func configure(with album: Album) {
		// Cover art
		os_signpost(.begin, log: .songsView, name: "Draw cover art")
		let coverArt = album.coverArt(
			at: CGSize(
				width: UIScreen.main.bounds.width,
				height: UIScreen.main.bounds.width))
		os_signpost(.end, log: .songsView, name: "Draw cover art")
		
		os_signpost(.begin, log: .songsView, name: "Set cover art")
		coverArtView.image = coverArt
		os_signpost(.end, log: .songsView, name: "Set cover art")
	}
}

final class AlbumInfoCell: UITableViewCell {
	@IBOutlet private var textStack: UIStackView!
	@IBOutlet private var albumArtistLabel: UILabel!
	@IBOutlet private var releaseDateLabel: UILabel!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityUserInputLabels = [""]
	}
	
	final func configure(with album: Album) {
		albumArtistLabel.text = { () -> String in // Don’t let this be `nil`.
			return album.albumArtistFormattedOrPlaceholder()
		}()
		releaseDateLabel.text = album.releaseDateEstimateFormatted() // Can be `nil`
		
		if releaseDateLabel.text == nil {
			// We couldn’t determine the album’s release date.
			textStack.spacing = 0
		} else {
			textStack.spacing = UIStackView.spacingUseSystem
		}
	}
	
	final override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.left = directionalLayoutMargins.leading
		separatorInset.right = directionalLayoutMargins.trailing
	}
}

final class SongCell: UITableViewCell {
	// `PlayheadReflectable`
	@IBOutlet var spacerSpeakerImageView: UIImageView!
	@IBOutlet var speakerImageView: UIImageView!
	
	@IBOutlet private var textStack: UIStackView!
	@IBOutlet private var titleLabel: UILabel!
	@IBOutlet private var artistLabel: UILabel!
	@IBOutlet private var spacerNumberLabel: UILabel!
	@IBOutlet private var numberLabel: UILabel!
	@IBOutlet private var dotDotDotButton: UIButton!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		tintSelectedBackgroundView()
		
		removeBackground()
		
		spacerNumberLabel.font = .monospacedDigitSystemFont(forTextStyle: .body)
		numberLabel.font = spacerNumberLabel.font
		
		if Enabling.songDotDotDot {
		} else {
			dotDotDotButton.removeFromSuperview()
			NSLayoutConstraint.activate([
				spacerSpeakerImageView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
			])
		}
		
		accessibilityTraits.formUnion(.button)
	}
	
	final func configureWith(
		song: Song,
		albumRepresentative representative: SongMetadatum?
	) {
		let metadatum = song.metadatum() // Can be `nil` if the user recently deleted the `SongMetadatum` from their library
		titleLabel.text = metadatum?.titleOnDisk ?? SongMetadatumExtras.unknownTitlePlaceholder
		artistLabel.text = {
			let albumArtist = representative?.albumArtistOnDisk // Can be `nil`
			if
				let songArtist = metadatum?.artistOnDisk,
				songArtist != albumArtist
			{
				return songArtist
			} else {
				return nil
			}}()
		numberLabel.text = { () -> String in // Don’t let this be `nil`.
			guard
				let metadatum = metadatum,
				let representative = representative
			else {
				return SongMetadatumExtras.unknownTrackNumberPlaceholder
			}
			
			let discNumber = representative.discNumberOnDisk
			let discCount = representative.discCountOnDisk
			// Show disc numbers if the disc count is more than 1, or if the disc count isn’t more than 1 but the disc number is.
			let shouldShowDiscNumber = (discCount > 1) ? true : (discNumber > 1)
			
			if shouldShowDiscNumber {
				return metadatum.discAndTrackNumberFormatted()
			} else {
				return metadatum.trackNumberFormatted()
			}}()
		
		if artistLabel.text == nil {
			textStack.spacing = 0
		} else {
			textStack.spacing = 4
		}
		
		accessibilityUserInputLabels = [metadatum?.titleOnDisk].compactMap { $0 }
		
		reflectPlayhead(containsPlayhead: song.containsPlayhead())
		
		guard Enabling.songDotDotDot else { return }
		guard let mediaItem = song.mpMediaItem() else {
			// TO DO: Prevent the button from highlighting itself when you touch it
			dotDotDotButton.tintColor = .placeholderText
			dotDotDotButton.menu = nil
			return
		}
		dotDotDotButton.tintColor = .label
		dotDotDotButton.menu = UIMenu(
			presentsUpward: false,
			groupedElements: [
				[
					// TO DO: Disable these if there are no songs below.
					UIAction(
						title: LocalizedString.playSongAndBelowNext,
						image: UIImage(systemName: "text.insert")
					) { _ in
						// ARC2DO
						self.player?.playNext([mediaItem]) // TO DO
					},
					UIAction(
						title: LocalizedString.playSongAndBelowLater,
						image: UIImage(systemName: "text.append")
					) { _ in
						// ARC2DO
						self.player?.playLast([mediaItem]) // TO DO
					},
				],
				[
					UIAction(
						title: LocalizedString.play,
						image: UIImage(systemName: "play") // TO DO: Reconsider
					) { _ in
						// ARC2DO
						self.player?.playNow([mediaItem])
					},
					UIAction(
						title: LocalizedString.playNext,
						image: UIImage(systemName: "arrow.turn.up.right")
					) { _ in
						// ARC2DO
						self.player?.playNext([mediaItem])
					},
					UIAction(
						title: LocalizedString.playLater,
						image: UIImage(systemName: "arrow.turn.down.right")
					) { _ in
						// ARC2DO
						self.player?.playLast([mediaItem])
					},
				],
			])
	}
	private var player: MPMusicPlayerController? { TapeDeck.shared.player }
	
	final override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.left = 0
		+ contentView.frame.minX // Content view’s leading edge to cell’s leading edge
		+ textStack.frame.minX // Text stack’s leading edge to content view’s leading edge
		separatorInset.right = directionalLayoutMargins.trailing
	}
}
extension SongCell:
	PlayheadReflectable,
	CellTintingWhenSelected,
	CellHavingTransparentBackground
{}
