//
//  Views - AlbumsTVC.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit

final class AlbumCell:
	UITableViewCell,
	NowPlayingIndicatorDisplayer
{
	@IBOutlet var artworkImageView: UIImageView!
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var releaseDateLabel: UILabel!
	@IBOutlet var nowPlayingIndicatorImageView: UIImageView!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		artworkImageView.accessibilityIgnoresInvertColors = true
	}
}

final class AlbumCellWithoutReleaseDate:
	UITableViewCell,
	NowPlayingIndicatorDisplayer
{
	@IBOutlet var artworkImageView: UIImageView!
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var nowPlayingIndicatorImageView: UIImageView!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		artworkImageView.accessibilityIgnoresInvertColors = true
	}
}
