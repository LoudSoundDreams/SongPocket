//
//  Collections - Views.swift
//  LavaRock
//
//  Created by h on 2020-11-06.
//

import UIKit

final class AllCollectionsCell: UITableViewCell {
	@IBOutlet var allLabel: UILabel!
	
	// ? set accessibilityTrait to .button
}

final class AllowAccessOrLoadingCell: UITableViewCell {
	@IBOutlet var allowAccessOrLoadingLabel: UILabel!
	@IBOutlet var spinnerView: UIActivityIndicatorView!
}

final class CollectionCell:
	UITableViewCell,
	NowPlayingIndicatorDisplayer
{
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var nowPlayingIndicatorImageView: UIImageView!
}
