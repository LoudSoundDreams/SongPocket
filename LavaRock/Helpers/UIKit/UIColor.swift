//
//  UIColor.swift
//  LavaRock
//
//  Created by h on 2021-11-01.
//

import UIKit

extension UIColor {
	
	static func tintColor(ifiOS14 accentColor: AccentColor) -> UIColor {
		if #available(iOS 15, *) {
			return .tintColor
		} else {
			return accentColor.uiColor
		}
	}
	
	private static let opacityForTranslucent: CGFloat = 1/8
	static func tintColorTranslucent(ifiOS14 accentColor: AccentColor) -> UIColor {
		return .tintColor(ifiOS14: accentColor).withAlphaComponent(opacityForTranslucent)
	}
	
}
