//
//  AccentColor.swift
//  LavaRock
//
//  Created by h on 2020-07-29.
//

import SwiftUI

extension AccentColor: Identifiable {
	var id: PersistentValue { persistentValue }
}

extension AccentColor {
	init?(persistentRawValue: PersistentValue.RawValue) {
		guard let matchingAccentColor = Self.all.first(where: { accentColor in
			persistentRawValue == accentColor.persistentValue.rawValue
		}) else {
			return nil
		}
		self = matchingAccentColor
	}
}

extension AccentColor {
	var uiColor: UIColor {
		switch persistentValue {
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
}

struct AccentColor: Equatable { // You can’t turn this into an enum, because raw values for enum cases need to be literals.
	enum PersistentValue: String, CaseIterable {
		// We persist these raw values in `UserDefaults`.
		case strawberry = "Strawberry"
		case tangerine = "Tangerine"
		case lime = "Lime"
		case blueberry = "Blueberry"
		case grape = "Grape"
	}
	
	let persistentValue: PersistentValue
	let displayName: String
	let color: Color
	let heartEmoji: String
	
	static let all = [
		Self(
			persistentValue: .strawberry,
			displayName: LocalizedString.strawberry,
			color: .pink,
			heartEmoji: "❤️"),
		Self(
			persistentValue: .tangerine,
			displayName: LocalizedString.tangerine,
			color: .orange,
			heartEmoji: "🧡"),
		Self(
			persistentValue: .lime,
			displayName: LocalizedString.lime,
			color: .green,
			heartEmoji: "💚"),
		
		defaultSelf,
		
		Self(
			persistentValue: .grape,
			displayName: LocalizedString.grape,
			color: .purple,
			heartEmoji: "💜"),
	]
	
	static func savedPreference() -> Self {
		userDefaults.register(defaults: [
			userDefaultsKey: defaultSelf.persistentValue.rawValue
		])
		let savedRawValue = userDefaults.string(forKey: userDefaultsKey)!
		let savedValue = PersistentValue(rawValue: savedRawValue)!
		return all.first { savedValue == $0.persistentValue }!
	}
	
	func saveAsPreference() {
		Self.userDefaults.set(
			persistentValue.rawValue,
			forKey: Self.userDefaultsKey)
	}
	
	// MARK: - PRIVATE
	
	private static let userDefaults = UserDefaults.standard
	private static let userDefaultsKey = LRUserDefaultsKey.accentColor.rawValue
	private static let defaultSelf = Self(
		persistentValue: .blueberry,
		displayName: LocalizedString.blueberry,
		color: .blue,
		heartEmoji: "💙")
}
