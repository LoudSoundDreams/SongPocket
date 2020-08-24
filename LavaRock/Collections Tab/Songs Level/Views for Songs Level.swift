//
//  Views for Songs Level.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit

final class SongsArtworkCell: UITableViewCell {
	@IBOutlet var artworkImageView: UIImageView!
}

final class SongsAlbumInfoHeaderCell: UITableViewCell {
	@IBOutlet var albumArtistLabel: UILabel!
	@IBOutlet var yearLabel: UILabel!
}

final class SongCell: UITableViewCell {
	@IBOutlet var trackNumberLabel: UILabel!
	@IBOutlet var titleLabel: UILabel!
}
