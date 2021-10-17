//
//  Songs - Views.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit
import MediaPlayer

final class AlbumArtworkCell: UITableViewCell {
	@IBOutlet var artworkImageView: UIImageView!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		artworkImageView.accessibilityIgnoresInvertColors = true
		accessibilityLabel = LocalizedString.albumArtwork
		accessibilityUserInputLabels = [""]
		accessibilityTraits.formUnion(.image)
	}
	
	final func configure(with album: Album) {
		// Artwork
		let artworkImage = album.artworkImage(at: CGSize( // Can be nil
			width: UIScreen.main.bounds.width,
			height: UIScreen.main.bounds.width))
		
		artworkImageView.image = artworkImage
	}
}

final class AlbumInfoCell: UITableViewCell {
	@IBOutlet var stackView: UIStackView!
	@IBOutlet var albumArtistLabel: UILabel!
	@IBOutlet var releaseDateLabel: UILabel!
	
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

final class SongCell: UITableViewCell {
	@IBOutlet var textStackView: UIStackView!
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var artistLabel: UILabel!
	@IBOutlet var nowPlayingIndicatorImageView: UIImageView!
	@IBOutlet var trackNumberLabel: UILabel!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		trackNumberLabel.font = .bodyWithMonospacedDigits
		
		accessibilityTraits.formUnion(.button)
	}
	
	final func configureWith(
//		song: Song,
//		album: Album
		title: String?,
		artist: String?, // Pass in `nil` if the song's artist is empty, or if it's the same as the album artist.
		trackNumberString: String
	) {
		titleLabel.text = title ?? MPMediaItem.placeholderTitle
		artistLabel.text = artist
//		applyNowPlayingIndicator(nowPlayingIndicator) // Cannot use mutating member on immutable value: 'self' is immutable
		trackNumberLabel.text = trackNumberString
		
		if artist == nil {
			textStackView.spacing = 0
		} else {
			textStackView.spacing = 4
		}
		
		accessibilityUserInputLabels = [title ?? MPMediaItem.placeholderTitle] // TO DO: Use something speakable; add (disc and) track numbers as labels too
	}
}

extension SongCell: NowPlayingIndicating {
}
