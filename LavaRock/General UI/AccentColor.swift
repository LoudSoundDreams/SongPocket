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
	init(persistentRawValue: PersistentValue.RawValue) {
		self = Self.all.first { accentColor in
			accentColor.persistentValue.rawValue == persistentRawValue
		}!
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
		let savedValueCase = PersistentValue(rawValue: savedRawValue)!
		
		let result = all.first { $0.persistentValue == savedValueCase }!
		return result
	}
	
	func saveAsPreference() {
		Self.userDefaults.set(
			persistentValue.rawValue,
			forKey: Self.userDefaultsKey)
	}
	
	// MARK: - PRIVATE
	
	private static let userDefaults = UserDefaults.standard
	private static let userDefaultsKey = LRUserDefaultsKey.accentColorName.rawValue
	private static let defaultSelf = Self(
		persistentValue: .blueberry,
		displayName: LocalizedString.blueberry,
		color: .blue,
		heartEmoji: "💙")
}
