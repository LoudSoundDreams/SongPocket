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
		accessibilityTraits.formUnion(.image)
	}
}

final class AlbumInfoCell: UITableViewCell {
	@IBOutlet var albumArtistLabel: UILabel!
	@IBOutlet var releaseDateLabel: UILabel!
}

final class AlbumInfoCellWithoutReleaseDate: UITableViewCell {
	@IBOutlet var albumArtistLabel: UILabel!
}

final class SongCell: UITableViewCell {
	@IBOutlet var textStackView: UIStackView!
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var artistLabel: UILabel!
	@IBOutlet var nowPlayingIndicatorImageView: UIImageView!
	@IBOutlet var trackNumberLabel: UILabel!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		trackNumberLabel.font = .bodyWithMonospacedNumbers
		
		accessibilityTraits.formUnion(.button)
	}
	
	final func configureWith(
		title: String?,
		artist: String?, // Pass in `nil` if the song's artist is empty, or if it's the same as the album artist.
//		trackNumber: Int?
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
