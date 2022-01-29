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
		
		freshenSelectedBackgroundView()
	}
	
	private func freshenSelectedBackgroundView() {
		let colorView = UIView()
		colorView.backgroundColor = .tintColor.translucent()
		selectedBackgroundView = colorView
	}
}
