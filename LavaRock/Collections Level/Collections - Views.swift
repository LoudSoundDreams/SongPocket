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

final class CollectionCell: UITableViewCell {
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var nowPlayingIndicatorImageView: UIImageView!
}

extension CollectionCell: NowPlayingIndicating {
}
