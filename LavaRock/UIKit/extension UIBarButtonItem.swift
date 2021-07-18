//
//  extension UIBarButtonItem.swift
//  LavaRock
//
//  Created by h on 2020-12-22.
//

import UIKit

extension UIBarButtonItem {
	
	// iOS 14: Use flexibleSpace().
	static func flexibleSpac3() -> UIBarButtonItem {
		return UIBarButtonItem(
			barButtonSystemItem: .flexibleSpace,
			target: nil,
			action: nil)
	}
	
	final func disableWithAccessibilityTrait() {
		isEnabled = false
		accessibilityTraits.formUnion(.notEnabled) // As of iOS 14.4 beta 1, setting isEnabled doesn't do this automatically
	}
	
	final func enableWithAccessibilityTrait() {
		isEnabled = true
		accessibilityTraits.subtract(.notEnabled)
	}
	
}
