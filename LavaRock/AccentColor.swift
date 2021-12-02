//
//  AccentColor.swift
//  LavaRock
//
//  Created by h on 2020-07-29.
//

import UIKit

struct AccentColor: Equatable { // You can't turn this into an enum, because raw values for enum cases need to be literals.
	
	enum ValueCase: String, CaseIterable {
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
	
	// MARK: - Restoring
	
	static func savedPreference() -> Self {
		let savedValueCase = savedValueCase()
		let result = all.first { $0.valueCase == savedValueCase }!
		return result
	}
	
	// MARK: - Setting
	
	func saveAsPreference() {
		Self.defaults.set(
			valueCase.rawValue,
			forKey: Self.defaultsKey)
	}
	
	func set(in window: UIWindow) {
		window.tintColor = uiColor
	}
	
	// MARK: - PRIVATE
	
	private static let defaults = UserDefaults.standard
	private static let defaultsKey = LRUserDefaultsKey.accentColorName.rawValue
	private static let defaultSelf = Self(
		valueCase: .blueberry,
		displayName: LocalizedString.blueberry,
		uiColor: .systemBlue,
		heartEmoji: "💙")
	
	// MARK: - Restoring
	
	private static func savedValueCase() -> ValueCase {
		defaults.register(defaults: [
			defaultsKey: defaultSelf.valueCase.rawValue
		])
		let savedRawValue = defaults.string(forKey: defaultsKey)!
		let result = ValueCase(rawValue: savedRawValue)!
		return result
	}
	
}
