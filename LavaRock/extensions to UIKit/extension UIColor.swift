//
//  extension UIColor.swift
//  extension UIColor
//
//  Created by h on 2021-08-01.
//

import UIKit

extension UIColor {
	
	static func tintColor(maybeResortTo window: UIWindow?) -> UIColor {
		// Xcode 13
//		if #available(iOS 15, *) {
//			return .tintColor
//		} else {
//			return window?.tintColor ?? AccentColor.savedPreference().uiColor
//		}
		
		// Xcode 12
		return window?.tintColor ?? AccentColor.savedPreference().uiColor
	}
	
}
