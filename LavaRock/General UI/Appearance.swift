//
//  Appearance.swift
//  LavaRock
//
//  Created by h on 2021-12-04.
//

import UIKit

extension Appearance: Identifiable {
	var id: RawValue { rawValue }
}

enum Appearance: Int, CaseIterable {
	// We persist these raw values in `UserDefaults`.
	// These raw values happen to match the raw values of `UIUserInterfaceStyle`.
	// Cases are in the order that they appear in in the UI.
	case light = 1
	case dark = 2
	case system = 0
	
	var indexInDisplayOrder: Int {
		return Self.allCases.firstIndex { $0 == self }!
	}
	
	var uiUserInterfaceStyle: UIUserInterfaceStyle {
		return UIUserInterfaceStyle(rawValue: rawValue)!
	}
	
	var sfSymbolName: String {
		switch self {
		case .light:
			return "sun.max.fill"
		case .dark:
			return "moon.fill"
		case .system:
			let idiom = UIDevice.current.userInterfaceIdiom
			switch idiom {
			case .unspecified:
				return "iphone"
			case .phone:
				return "iphone"
			case .pad:
				return "ipad"
			case .tv:
				return "tv"
			case .carPlay:
				return "iphone"
			case .mac:
				return "desktopcomputer"
			@unknown default:
				return "iphone"
			}
		}
	}
	
	var name: String {
		switch self {
		case .light:
			return LocalizedString.light
		case .dark:
			return LocalizedString.dark
		case .system:
			return LocalizedString.system
		}
	}
	
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
}
