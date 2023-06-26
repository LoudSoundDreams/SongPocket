//
//  UIBarButtonItem.swift
//  LavaRock
//
//  Created by h on 2020-12-22.
//

import UIKit

extension UIBarButtonItem {
	final func isEnabled_setFalseWithAxTrait() {
		isEnabled = false
		accessibilityTraits.formUnion(.notEnabled) // As of iOS 15.3 developer beta 1, setting `isEnabled` doesn’t do this automatically.
	}
	
	final func isEnabled_setTrueWithAxTrait() {
		isEnabled = true
		accessibilityTraits.subtract(.notEnabled)
	}
}
