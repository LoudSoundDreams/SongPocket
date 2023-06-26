//
//  UITableViewCell.swift
//  LavaRock
//
//  Created by h on 2021-08-22.
//

import UIKit

extension UITableViewCell {
	final func isUserInteractionEnabled_setFalseWithAxTrait() {
		isUserInteractionEnabled = false
		accessibilityTraits.formUnion(.notEnabled)
	}
	
	final func isUserInteractionEnabled_setTrueWithAxTrait() {
		isUserInteractionEnabled = true
		accessibilityTraits.subtract(.notEnabled)
	}
	
	final func backgroundColor_set_to_clear() {
		backgroundColor = .clear
	}
	
	final func selectedBackgroundView_add_tint() {
		let colorView = UIView()
		colorView.backgroundColor = .tintColor.withAlphaComponentOneHalf()
		selectedBackgroundView = colorView
	}
}
