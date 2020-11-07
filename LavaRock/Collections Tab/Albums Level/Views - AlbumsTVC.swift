//
//  Views - AlbumsTVC.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit

final class AlbumCell: UITableViewCell {
	@IBOutlet var artworkImageView: UIImageView!
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var releaseDateLabel: UILabel!
	@IBOutlet var currentSongIndicatorImageView: UIImageView!
}

final class AlbumCellWithoutReleaseDate: UITableViewCell {
	@IBOutlet var artworkImageView: UIImageView!
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var currentSongIndicatorImageView: UIImageView!
}
