//
//  Views - OptionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-12-27.
//

import UIKit

final class TipReloadCell: UITableViewCell {
	@IBOutlet var reloadLabel: UILabel!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
	}
}

final class TipReadyCell: UITableViewCell {
	@IBOutlet var tipNameLabel: UILabel!
	@IBOutlet var tipPriceLabel: UILabel!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
	}
}

final class TipThankYouCell: UITableViewCell {
	@IBOutlet var thankYouLabel: UILabel!
}
