//
//  UIBarButtonItem.swift
//  LavaRock
//
//  Created by h on 2020-12-22.
//

import UIKit

extension UIBarButtonItem {
	// Similar to UITableViewCell.disableWithAccessibilityTrait.
	final func disableWithAccessibilityTrait() {
		isEnabled = false
		accessibilityTraits.formUnion(.notEnabled) // As of iOS 14.4 developer beta 1, setting `isEnabled` doesn't do this automatically. // TO DO: Is that still true?
	}
	
	// Similar to UITableViewCell.enableWithAccessibilityTrait.
	final func enableWithAccessibilityTrait() {
		isEnabled = true
		accessibilityTraits.subtract(.notEnabled)
	}
}
