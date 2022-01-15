//
//  AccentColor.swift
//  LavaRock
//
//  Created by h on 2020-07-29.
//

import SwiftUI

struct AccentColor: Equatable { // You can’t turn this into an enum, because raw values for enum cases need to be literals.
	enum ValueCase: String, CaseIterable {
		// We persist these raw values in `UserDefaults`.
		case strawberry = "Strawberry"
		case tangerine = "Tangerine"
		case lime = "Lime"
		case blueberry = "Blueberry"
		case grape = "Grape"
	}
	
	let valueCase: ValueCase
	let displayName: String
	let color: Color
	let heartEmoji: String
	
	static let all = [
		Self(
			valueCase: .strawberry,
			displayName: LocalizedString.strawberry,
			color: .pink,
			heartEmoji: "❤️"),
		Self(
			valueCase: .tangerine,
			displayName: LocalizedString.tangerine,
			color: .orange,
			heartEmoji: "🧡"),
		Self(
			valueCase: .lime,
			displayName: LocalizedString.lime,
			color: .green,
			heartEmoji: "💚"),
		
		defaultSelf,
		
		Self(
			valueCase: .grape,
			displayName: LocalizedString.grape,
			color: .purple,
			heartEmoji: "💜"),
	]
	
	static func savedPreference() -> Self {
		userDefaults.register(defaults: [
			userDefaultsKey: defaultSelf.valueCase.rawValue
		])
		let savedRawValue = userDefaults.string(forKey: userDefaultsKey)!
		let savedValueCase = ValueCase(rawValue: savedRawValue)!
		
		let result = all.first { $0.valueCase == savedValueCase }!
		return result
	}
	
	func saveAsPreference() {
		Self.userDefaults.set(
			valueCase.rawValue,
			forKey: Self.userDefaultsKey)
	}
	
	// MARK: - PRIVATE
	
	private static let userDefaults = UserDefaults.standard
	private static let userDefaultsKey = LRUserDefaultsKey.accentColorName.rawValue
	private static let defaultSelf = Self(
		valueCase: .blueberry,
		displayName: LocalizedString.blueberry,
		color: .blue,
		heartEmoji: "💙")
}

extension AccentColor: Identifiable {
	var id: ValueCase { valueCase }
}

extension AccentColor {
	init(persistentRawValue: ValueCase.RawValue) {
		self = Self.all.first { accentColor in
			accentColor.valueCase.rawValue == persistentRawValue
		}!
	}
}
