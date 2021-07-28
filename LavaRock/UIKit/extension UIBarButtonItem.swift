//
//  extension UIBarButtonItem.swift
//  LavaRock
//
//  Created by h on 2020-12-22.
//

import UIKit

extension UIBarButtonItem {
	
	final func disableWithAccessibilityTrait() {
		isEnabled = false
		accessibilityTraits.formUnion(.notEnabled) // As of iOS 14.4 beta 1, setting isEnabled doesn't do this automatically
	}
	
	final func enableWithAccessibilityTrait() {
		isEnabled = true
		accessibilityTraits.subtract(.notEnabled)
	}
	
}
