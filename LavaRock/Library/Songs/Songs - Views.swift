//
//  Songs - Views.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit
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
		let artworkImage = album.artworkImage( // Can be nil
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
		// Album artist
		let albumArtist: String // Don’t let this be `nil`.
		= album.albumArtistFormattedOrPlaceholder()
		
		// Release date
		let releaseDateString = album.releaseDateEstimateFormatted() // Can be `nil`
		
		albumArtistLabel.text = albumArtist
		releaseDateLabel.text = releaseDateString
		
		if releaseDateString == nil {
			// We couldn’t determine the album’s release date.
			textStack.spacing = 0
		} else {
			textStack.spacing = UIStackView.spacingUseSystem
		}
	}
}

final class SongCell:
	TintedSelectedCell,
	CellHavingTransparentBackground
{
	@IBOutlet private var textStack: UIStackView!
	@IBOutlet private var titleLabel: UILabel!
	@IBOutlet private var artistLabel: UILabel!
	@IBOutlet var nowPlayingImageView: UIImageView!
	@IBOutlet private var trackLabel: UILabel!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		setTransparentBackground()
		
		trackLabel.font = .bodyWithMonospacedDigits(compatibleWith: traitCollection)
		
		accessibilityTraits.formUnion(.button)
	}
	
	final func configureWith(
		metadatum: SongMetadatum?,
		albumRepresentative representative: SongMetadatum?
	) {
		let titleText = metadatum?.titleOnDisk ?? SongMetadatumExtras.unknownTitlePlaceholder
		let artistText: String? = {
			let albumArtist = representative?.albumArtistOnDisk // Can be `nil`
			if
				let songArtist = metadatum?.artistOnDisk,
				songArtist != albumArtist
			{
				return songArtist
			} else {
				return nil
			}
		}()
		let trackNumberString: String = { // Don’t let this be `nil`.
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
			}
		}()
		
		titleLabel.text = titleText
		artistLabel.text = artistText
		trackLabel.text = trackNumberString
		
		if artistText == nil {
			textStack.spacing = 0
		} else {
			textStack.spacing = 4
		}
		
		accessibilityUserInputLabels = [metadatum?.titleOnDisk].compactMap { $0 }
	}
}

extension SongCell: NowPlayingIndicating {
}
