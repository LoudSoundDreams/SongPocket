//
//  UITableViewCell.swift
//  LavaRock
//
//  Created by h on 2021-08-22.
//

import UIKit

extension UITableViewCell {
	
	// Similar to UIBarButtonItem.disableWithAccessibilityTrait.
	final func disableWithAccessibilityTrait() {
		isUserInteractionEnabled = false
		accessibilityTraits.formUnion(.notEnabled)
	}
	
	// Similar to UIBarButtonItem.enableWithAccessibilityTrait.
	final func enableWithAccessibilityTrait() {
		isUserInteractionEnabled = true
		accessibilityTraits.subtract(.notEnabled)
	}
	
}
