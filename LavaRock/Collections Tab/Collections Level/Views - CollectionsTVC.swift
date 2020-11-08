//
//  Views - CollectionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-11-06.
//

import UIKit

final class CollectionCell:
	UITableViewCell,
	NowPlayingIndicator
{
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var nowPlayingIndicatorImageView: UIImageView!
}
