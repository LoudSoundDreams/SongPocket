//
//  AccentColor.swift
//  LavaRock
//
//  Created by h on 2020-07-29.
//

import UIKit

struct AccentColor: Equatable { // You can't turn this into an enum, because raw values for enum cases need to be literals.
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
	let uiColor: UIColor
	let heartEmoji: String
	
	static let all = [
		Self(
			valueCase: .strawberry,
			displayName: LocalizedString.strawberry,
			uiColor: .systemPink,
			heartEmoji: "❤️"),
		Self(
			valueCase: .tangerine,
			displayName: LocalizedString.tangerine,
			uiColor: .systemOrange,
			heartEmoji: "🧡"),
		Self(
			valueCase: .lime,
			displayName: LocalizedString.lime,
			uiColor: .systemGreen,
			heartEmoji: "💚"),
		
		defaultSelf,
		
		Self(
			valueCase: .grape,
			displayName: LocalizedString.grape,
			uiColor: .systemPurple,
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
		uiColor: .systemBlue,
		heartEmoji: "💙")
}
