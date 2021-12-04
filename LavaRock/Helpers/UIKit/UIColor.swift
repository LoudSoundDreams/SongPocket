//
//  UIColor.swift
//  LavaRock
//
//  Created by h on 2021-11-01.
//

import UIKit

extension UIColor {
	
	static func tintColor_() -> UIColor {
		if #available(iOS 15, *) {
			return .tintColor
		} else {
			return AccentColor.savedPreference().uiColor
		}
	}
	
	func translucentFaint() -> UIColor {
		return withAlphaComponent(1/8)
	}
	
	final func translucentVibrant() -> UIColor {
		return withAlphaComponent(1/2)
	}
	
}
