//
//  songs view cells.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit

final class SongsArtworkCell: UITableViewCell {
	@IBOutlet var artworkImageView: UIImageView!
}

//final class SongsHeaderCellWithButton: UITableViewCell {
//	@IBOutlet var albumArtistLabel: UILabel!
//	@IBOutlet var yearLabel: UILabel!
//	@IBOutlet var addAllToDeckButton: UIButton!
//}

final class SongsHeaderCellWithoutButton: UITableViewCell {
	@IBOutlet var albumArtistLabel: UILabel!
	@IBOutlet var yearLabel: UILabel!
}

final class SongCellWithoutMoreButton: UITableViewCell {
	@IBOutlet var trackNumberLabel: UILabel!
	@IBOutlet var titleLabel: UILabel!
}

final class SongCellWithMoreButton: UITableViewCell {
	@IBOutlet var trackNumberLabel: UILabel!
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var moreButton: UIButton!
}
