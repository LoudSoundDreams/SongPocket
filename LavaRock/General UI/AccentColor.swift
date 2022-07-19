//
//  AccentColor.swift
//  LavaRock
//
//  Created by h on 2020-07-29.
//

import SwiftUI
import UIKit

extension Notification.Name {
	static let savedAccentColor = Self("saved accent color")
}

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
	
	private static let defaults = UserDefaults.standard
	private static let defaultsKey = LRUserDefaultsKey.accentColor.rawValue
	
	static func savedPreference() -> Self {
		defaults.register(defaults: [defaultsKey: blueberry.rawValue])
		let savedRawValue = defaults.string(forKey: defaultsKey)!
		return Self(rawValue: savedRawValue)!
	}
	
	func saveAsPreference() {
		Self.defaults.set(
			rawValue,
			forKey: Self.defaultsKey)
		
		NotificationCenter.default.post(name: .savedAccentColor, object: nil)
	}
	
	var displayName: String {
		switch self {
		case .strawberry:
			return LRString.strawberry
		case .tangerine:
			return LRString.tangerine
		case .lime:
			return LRString.lime
		case .blueberry:
			return LRString.blueberry
		case .grape:
			return LRString.grape
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
