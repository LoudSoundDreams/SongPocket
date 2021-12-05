//
//  AccentColorSelectedCell.swift
//  LavaRock
//
//  Created by h on 2021-12-03.
//

import UIKit

class AccentColorSelectedCell: UITableViewCell {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		refreshSelectedBackgroundView()
	}
	
	private func refreshSelectedBackgroundView() {
		let colorView = UIView()
		colorView.backgroundColor = .tintColor_().translucent()
		selectedBackgroundView = colorView
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		
		if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
			refreshSelectedBackgroundView()
		}
	}
}

