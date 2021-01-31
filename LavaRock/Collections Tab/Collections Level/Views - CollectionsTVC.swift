//
//  Views - CollectionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-11-06.
//

import UIKit

final class AllowAccessCell: UITableViewCell {
	@IBOutlet var label: UILabel!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
	}
}

final class CollectionCell:
	UITableViewCell,
	NowPlayingIndicator
{
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var nowPlayingIndicatorImageView: UIImageView!
}
