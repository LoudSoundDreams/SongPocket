//
//  UIBarButtonItem.swift
//  LavaRock
//
//  Created by h on 2020-12-22.
//

import UIKit

extension UIBarButtonItem {
	// Similar to counterpart in `UITableViewCell`.
	final func disableWithAccessibilityTrait() {
		isEnabled = false
		accessibilityTraits.formUnion(.notEnabled) // As of iOS 15.3 developer beta 1, setting `isEnabled` doesn’t do this automatically.
	}
	
	// Similar to counterpart in `UITableViewCell`.
	final func enableWithAccessibilityTrait() {
		isEnabled = true
		accessibilityTraits.subtract(.notEnabled)
	}
}
