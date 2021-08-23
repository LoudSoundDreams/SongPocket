//
//  Albums - Views.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit

final class AlbumCell: UITableViewCell {
	@IBOutlet var artworkImageView: UIImageView!
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var releaseDateLabel: UILabel!
	@IBOutlet var nowPlayingIndicatorImageView: UIImageView!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		artworkImageView.accessibilityIgnoresInvertColors = true
	}
}

extension AlbumCell: NowPlayingIndicating {
}

final class AlbumCellWithoutReleaseDate: UITableViewCell {
	@IBOutlet var artworkImageView: UIImageView!
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var nowPlayingIndicatorImageView: UIImageView!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		artworkImageView.accessibilityIgnoresInvertColors = true
	}
}

extension AlbumCellWithoutReleaseDate: NowPlayingIndicating {
}
