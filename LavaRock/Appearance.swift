//
//  Appearance.swift
//  LavaRock
//
//  Created by h on 2021-12-04.
//

import UIKit

enum Appearance: Int, CaseIterable {
	// Match the order of the segmented controls in the storyboard.
	// Raw values are the raw values of `UIUserInterfaceStyle`, which we also persist in `UserDefaults`.
	case light = 1
	case dark = 2
	case system = 0
	
	init(indexInDisplayOrder: Int) {
		self = Self.allCases[indexInDisplayOrder]
	}
	
	static func savedPreference() -> Self {
		let savedStyleValue = UserDefaults.standard.integer(
			forKey: LRUserDefaultsKey.appearance.rawValue) // Returns `0` when there's no saved value, which happens to be `UIUserInterfaceStyle.unspecified`, which is what we want.
		return Self(rawValue: savedStyleValue)!
	}
	
	func saveAsPreference() {
		UserDefaults.standard.set(
			rawValue,
			forKey: LRUserDefaultsKey.appearance.rawValue)
	}
	
	func uiUserInterfaceStyle() -> UIUserInterfaceStyle {
		return UIUserInterfaceStyle(rawValue: rawValue)!
	}
	
	func indexInDisplayOrder() -> Int {
		let result = Self.allCases.firstIndex { appearance in
			appearance == self
		}!
		return result
	}
}
