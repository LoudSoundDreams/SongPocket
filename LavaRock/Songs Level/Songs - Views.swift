//
//  Songs - Views.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit

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

final class SongCell:
	UITableViewCell,
	NowPlayingIndicatorDisplayer
{
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var nowPlayingIndicatorImageView: UIImageView!
	@IBOutlet var trackNumberLabel: UILabel!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
	}
}

final class SongCellWithDifferentArtist:
	UITableViewCell,
	NowPlayingIndicatorDisplayer
{
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var artistLabel: UILabel!
	@IBOutlet var nowPlayingIndicatorImageView: UIImageView!
	@IBOutlet var trackNumberLabel: UILabel!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
	}
}
