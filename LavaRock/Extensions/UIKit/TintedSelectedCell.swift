//
//  TintedSelectedCell.swift
//  LavaRock
//
//  Created by h on 2021-12-03.
//

import UIKit

class TintedSelectedCell: UITableViewCell {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		refreshSelectedBackgroundView()
	}
	
	private func refreshSelectedBackgroundView() {
		let colorView = UIView()
		colorView.backgroundColor = .tintColor.translucent()
		selectedBackgroundView = colorView
	}
}
