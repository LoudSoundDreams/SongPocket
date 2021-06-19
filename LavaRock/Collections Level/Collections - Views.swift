//
//  Collections - Views.swift
//  LavaRock
//
//  Created by h on 2020-11-06.
//

import UIKit

final class AllowAccessOrLoadingCell: UITableViewCell {
	/*
	I’ve implemented this cell using a subclass of UITableViewCell rather than a built-in cell style because …
	1. Its height should exactly match the height of a Collection cell for a smooth transition after loading.
	- - In turn, I’ve implemented Collection cells with custom subclasses because they need “now playing” indicators.
	2. It needs a spinner in the “Loading…” state.
	*/
	
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
