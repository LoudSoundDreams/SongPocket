//
//  Songs - Views.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit
import MediaPlayer

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
		let artworkImage = album.artworkImage( // Can be nil
			at: CGSize(
				width: UIScreen.main.bounds.width,
				height: UIScreen.main.bounds.width))
		
		artworkImageView.image = artworkImage
	}
}

final class AlbumInfoCell: UITableViewCell {
	@IBOutlet private var stackView: UIStackView!
	@IBOutlet private var albumArtistLabel: UILabel!
	@IBOutlet private var releaseDateLabel: UILabel!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityUserInputLabels = [""]
	}
	
	final func configure(with album: Album) {
		// Album artist
		let albumArtist: String // Don't let this be nil.
		= album.albumArtistFormattedOrPlaceholder()
		
		// Release date
		let releaseDateString = album.releaseDateEstimateFormatted() // Can be nil
		
		albumArtistLabel.text = albumArtist
		releaseDateLabel.text = releaseDateString
		
		if releaseDateString == nil {
			// We couldn't determine the album's release date.
			stackView.spacing = 0
		} else {
			stackView.spacing = UIStackView.spacingUseSystem
		}
	}
}

final class SongCell:
	TintedSelectedCell,
	TranslucentBackgroundCell
{
	@IBOutlet private var textStackView: UIStackView!
	@IBOutlet private var titleLabel: UILabel!
	@IBOutlet private var artistLabel: UILabel!
	@IBOutlet var nowPlayingIndicatorImageView: UIImageView!
	@IBOutlet private var trackNumberLabel: UILabel!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		// TranslucentBackgroundCell
		setNormalBackground()
		
		trackNumberLabel.font = .bodyWithMonospacedDigits(compatibleWith: traitCollection)
		
		accessibilityTraits.formUnion(.button)
	}
	
	final func configureWith(
		mediaItem: MPMediaItem?,
		albumRepresentative representativeItem: MPMediaItem?
	) {
		let titleText = mediaItem?.title ?? MPMediaItem.unknownTitlePlaceholder
		let artistText: String? = {
			let albumArtist = representativeItem?.albumArtist // Can be `nil`
			if
				let songArtist = mediaItem?.artist,
				songArtist != albumArtist
			{
				return songArtist
			} else {
				return nil
			}
		}()
		let trackNumberString: String = { // Don't let this be nil.
			guard
				let mediaItem = mediaItem,
				let representativeItem = representativeItem
			else { return MPMediaItem.unknownTrackNumberPlaceholder }
			
			let discNumber = representativeItem.discNumber
			let discCount = representativeItem.discCount
			// Show disc numbers if the disc count is more than 1, or if the disc count isn't more than 1 but the disc number is.
			let shouldShowDiscNumber: Bool = {
				discCount > 1 // As of iOS 15.0 RC, MediaPlayer sometimes reports `discCount == 0` for albums with 1 disc.
				? true
				: discNumber > 1
			}()
			
			if shouldShowDiscNumber {
				return mediaItem.discAndTrackNumberFormatted()
			} else {
				return mediaItem.trackNumberFormatted()
			}
		}()
		
		titleLabel.text = titleText
		artistLabel.text = artistText
//		applyNowPlayingIndicator(nowPlayingIndicator) // Cannot use mutating member on immutable value: 'self' is immutable
		trackNumberLabel.text = trackNumberString
		
		if artistText == nil {
			textStackView.spacing = 0
		} else {
			textStackView.spacing = 4
		}
		
		accessibilityUserInputLabels = [mediaItem?.title].compactMap { $0 }
	}
}

extension SongCell: NowPlayingIndicating {
}
