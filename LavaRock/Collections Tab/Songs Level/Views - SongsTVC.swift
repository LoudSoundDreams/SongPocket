//
//  Views - SongsTVC.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit

final class AlbumArtworkCell: UITableViewCell {
	@IBOutlet var artworkImageView: UIImageView!
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		accessibilityLabel = LocalizedString.albumArtwork // should never change
		accessibilityTraits.formUnion(.image) // should never change
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
	NowPlayingIndicator
{
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var nowPlayingIndicatorImageView: UIImageView!
	@IBOutlet var trackNumberLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
	}
}

final class SongCellWithDifferentArtist:
	UITableViewCell,
	NowPlayingIndicator
{
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var artistLabel: UILabel!
	@IBOutlet var nowPlayingIndicatorImageView: UIImageView!
	@IBOutlet var trackNumberLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
	}
}
