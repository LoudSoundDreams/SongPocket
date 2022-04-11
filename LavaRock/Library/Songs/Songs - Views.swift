//
//  Songs - Views.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit
import MediaPlayer
import OSLog

final class AlbumArtworkCell: UITableViewCell {
	@IBOutlet private var artworkImageView: UIImageView!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		artworkImageView.accessibilityIgnoresInvertColors = true
		accessibilityLabel = LocalizedString.albumArtwork
		accessibilityUserInputLabels = [""]
		accessibilityTraits.formUnion(.image)
	}
	
	final func configure(with album: Album) {
		// Artwork
		os_signpost(.begin, log: .songsView, name: "Draw artwork image")
		let artworkImage = album.artworkImage(
			at: CGSize(
				width: UIScreen.main.bounds.width,
				height: UIScreen.main.bounds.width))
		os_signpost(.end, log: .songsView, name: "Draw artwork image")
		
		os_signpost(.begin, log: .songsView, name: "Set artwork image")
		artworkImageView.image = artworkImage
		os_signpost(.end, log: .songsView, name: "Set artwork image")
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
}

final class SongCell: UITableViewCell {
	// `NowPlayingIndicating`
	@IBOutlet var spacerSpeakerImageView: UIImageView!
	@IBOutlet var speakerImageView: UIImageView!
	
	@IBOutlet private var textStack: UIStackView!
	@IBOutlet private var titleLabel: UILabel!
	@IBOutlet private var artistLabel: UILabel!
	@IBOutlet private var spacerNumberLabel: UILabel!
	@IBOutlet private var numberLabel: UILabel!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		tintSelectedBackgroundView()
		
		removeBackground()
		
		spacerNumberLabel.font = .monospacedDigitSystemFont(forTextStyle: .body)
		numberLabel.font = spacerNumberLabel.font
		
		accessibilityTraits.formUnion(.button)
	}
	
	final func configureWith(
		song: Song?,
		albumRepresentative representative: SongMetadatum?
	) {
		let metadatum = song?.metadatum()
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
	}
	
	final override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.left = {
			return 0
			+ contentView.frame.minX // Non-editing mode: 0. Editing mode: ~44.
			+ textStack.frame.minX
		}()
	}
}
extension SongCell:
	NowPlayingIndicating,
	CellTintingWhenSelected,
	CellHavingTransparentBackground
{}
