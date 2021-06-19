//
//  AccentColor.swift
//  LavaRock
//
//  Created by h on 2020-07-29.
//

import UIKit

struct AccentColor: Equatable { // You can't make this an enum, because raw values for enum cases need to be literals.
	
	// MARK: - Types
	
	enum UserDefaultsValueCase: String, CaseIterable {
		case strawberry = "Strawberry"
		case tangerine = "Tangerine"
		case lime = "Lime"
		case blueberry = "Blueberry"
		case grape = "Grape"
	}
	
	// MARK: - Properties
	
	// MARK: Instance Properties
	
	let userDefaultsValueCase: UserDefaultsValueCase
	let displayName: String
	let uiColor: UIColor
	let heartEmoji: String
	
	// MARK: Type Properties
	
	static let all = [
		Self(
			userDefaultsValueCase: .strawberry,
			displayName: LocalizedString.strawberry,
			uiColor: .systemPink,
			heartEmoji: "❤️"),
		Self(
			userDefaultsValueCase: .tangerine,
			displayName: LocalizedString.tangerine,
			uiColor: .systemOrange,
			heartEmoji: "🧡"),
		Self(
			userDefaultsValueCase: .lime,
			displayName: LocalizedString.lime,
			uiColor: .systemGreen,
			heartEmoji: "💚"),
		
		defaultAccentColor,
		
		Self(
			userDefaultsValueCase: .grape,
			displayName: LocalizedString.grape,
			uiColor: .systemPurple,
			heartEmoji: "💜"),
	]
	
	// MARK: - Restoring and Setting
	
	static func restore(in window: UIWindow?) {
		let accentColorToSet = savedPreferenceOrDefault()
		accentColorToSet.set(in: window)
	}
	
	func set(in window: UIWindow?) {
		window?.tintColor = uiColor // This doesn't trigger tintColorDidChange() on LibraryTVC's table view, so we'll post our own notification.
		NotificationCenter.default.post(
			Notification(name: .LRDidChangeAccentColor)
		)
		
		UserDefaults.standard.set(
			userDefaultsValueCase.rawValue,
			forKey: UserDefaults.LRKey.accentColorName.rawValue)
	}
	
	// MARK: - Getting Saved Value
	
	static func savedPreferenceOrDefault() -> Self {
		return savedPreference() ?? defaultAccentColor
	}
	
	static func savedPreference() -> Self? {
		// If there's a saved preference, return that.
		if
			let savedUserDefaultsValueCase = savedUserDefaultsValueCase(),
			let result = all.first(where: { accentColor in
				accentColor.userDefaultsValueCase == savedUserDefaultsValueCase
			})
		{
			return result
		} else { // There was no saved preference, or it didn't match any AccentColor.
			return nil
		}
	}
	
	// MARK: - PRIVATE
	
	// MARK: - Properties
	
	// MARK: Type Properties
	
	private static let defaultAccentColor = Self(
		userDefaultsValueCase: .blueberry,
		displayName: LocalizedString.blueberry,
		uiColor: .systemBlue,
		heartEmoji: "💙")
	
	// MARK: - Getting Saved Value
	
	private static func savedUserDefaultsValueCase() -> UserDefaultsValueCase? {
		guard let savedUserDefaultsValue = UserDefaults.standard.value(
				forKey: UserDefaults.LRKey.accentColorName.rawValue) as? String else {
			return nil
		}
		return UserDefaultsValueCase(rawValue: savedUserDefaultsValue)
	}
	
}
