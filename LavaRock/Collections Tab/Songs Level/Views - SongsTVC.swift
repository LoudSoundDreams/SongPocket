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
		
		accessibilityLabel = "Album artwork" // should never change
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
	UITableViewCell//,
//	CurrentSongIndicator
{
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var currentSongIndicatorImageView: UIImageView!
	@IBOutlet var trackNumberLabel: UILabel!
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		accessibilityTraits.formUnion(.button)
	}
}

final class SongCellWithDifferentArtist:
	UITableViewCell//,
//	CurrentSongIndicator
{
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var artistLabel: UILabel!
	@IBOutlet var currentSongIndicatorImageView: UIImageView!
	@IBOutlet var trackNumberLabel: UILabel!
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		accessibilityTraits.formUnion(.button)
	}
}
