//
//  Views - SongsTVC.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit

final class AlbumArtworkCell: UITableViewCell {
	@IBOutlet var artworkImageView: UIImageView!
}

final class AlbumInfoCell: UITableViewCell {
	@IBOutlet var albumArtistLabel: UILabel!
	@IBOutlet var releaseDateLabel: UILabel!
}

final class AlbumInfoCellWithoutReleaseDate: UITableViewCell {
	@IBOutlet var albumArtistLabel: UILabel!
}

final class SongCell: UITableViewCell {
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var currentSongIndicatorImageView: UIImageView!
	@IBOutlet var trackNumberLabel: UILabel!
}

final class SongCellWithDifferentArtist: UITableViewCell {
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var artistLabel: UILabel!
	@IBOutlet var currentSongIndicatorImageView: UIImageView!
	@IBOutlet var trackNumberLabel: UILabel!
}
