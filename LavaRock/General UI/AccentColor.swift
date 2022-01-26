//
//  AccentColor.swift
//  LavaRock
//
//  Created by h on 2020-07-29.
//

import SwiftUI
import UIKit

extension AccentColor: Identifiable {
	var id: RawValue { rawValue }
}

enum AccentColor: String, CaseIterable {
	// We persist these raw values in `UserDefaults`.
	case strawberry = "Strawberry"
	case tangerine = "Tangerine"
	case lime = "Lime"
	case blueberry = "Blueberry"
	case grape = "Grape"
	
	private static let userDefaults = UserDefaults.standard
	private static let userDefaultsKey = LRUserDefaultsKey.accentColor.rawValue
	
	static func savedPreference() -> Self {
		userDefaults.register(defaults: [
			userDefaultsKey: blueberry.rawValue,
		])
		let savedRawValue = userDefaults.string(forKey: userDefaultsKey)!
		return Self(rawValue: savedRawValue)!
	}
	
	func saveAsPreference() {
		Self.userDefaults.set(
			rawValue,
			forKey: Self.userDefaultsKey)
	}
	
	var displayName: String {
		switch self {
		case .strawberry:
			return LocalizedString.strawberry
		case .tangerine:
			return LocalizedString.tangerine
		case .lime:
			return LocalizedString.lime
		case .blueberry:
			return LocalizedString.blueberry
		case .grape:
			return LocalizedString.grape
		}
	}
	
	var color: Color {
		switch self {
		case .strawberry:
			return .pink
		case .tangerine:
			return .orange
		case .lime:
			return .green
		case .blueberry:
			return .blue
		case .grape:
			return .purple
		}
	}
	
	var uiColor: UIColor {
		switch self {
		case .strawberry:
			return .systemPink
		case .tangerine:
			return .systemOrange
		case .lime:
			return .systemGreen
		case .blueberry:
			return .systemBlue
		case .grape:
			return .systemPurple
		}
	}
	
	var heartEmoji: String {
		switch self {
		case .strawberry:
			return "❤️"
		case .tangerine:
			return "🧡"
		case .lime:
			return "💚"
		case .blueberry:
			return "💙"
		case .grape:
			return "💜"
		}
	}
}
