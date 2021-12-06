//
//  Appearance.swift
//  LavaRock
//
//  Created by h on 2021-12-04.
//

import UIKit

enum Appearance: Int, CaseIterable {
	// Cases are in the order that they appear in in the UI.
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
	
	func image() -> UIImage {
		switch self {
		case .light:
			let image = UIImage(systemName: "sun.max.fill")!
			image.accessibilityLabel = LocalizedString.light
			return image
		case .dark:
			let image = UIImage(systemName: "moon.fill")!
			image.accessibilityLabel = LocalizedString.dark
			return image
		case .system:
			let image: UIImage = {
				let idiom = UIDevice.current.userInterfaceIdiom
				switch idiom {
				case .unspecified:
					return UIImage(systemName: "iphone")!
				case .phone:
					return UIImage(systemName: "iphone")!
				case .pad:
					return UIImage(systemName: "ipad")!
				case .tv:
					return UIImage(systemName: "tv")!
				case .carPlay:
					return UIImage(systemName: "iphone")!
				case .mac:
					return UIImage(systemName: "desktopcomputer")!
				@unknown default:
					return UIImage(systemName: "iphone")!
				}
			}()
			image.accessibilityLabel = LocalizedString.system
			return image
		}
	}
}
