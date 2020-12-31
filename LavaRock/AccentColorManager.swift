//
//  AccentColorManager.swift
//  LavaRock
//
//  Created by h on 2020-07-29.
//

import UIKit

struct AccentColorManager {
	
	// MARK: - Types
	
	private enum UserDefaultsValueCase: String, CaseIterable {
		case strawberry = "Strawberry"
		case tangerine = "Tangerine"
		case lime = "Lime"
		case blueberry = "Blueberry"
		case grape = "Grape"
	}
	
	struct ColorEntry {
		let userDefaultsValue: String
		let displayName: String
		let uiColor: UIColor
	}
	
	// MARK: - Properties
	
	private static let defaultColorEntry = ColorEntry(
		userDefaultsValue: UserDefaultsValueCase.blueberry.rawValue,
		displayName: LocalizedString.blueberry,
		uiColor: UIColor.systemBlue)
	
	static let colorEntries = [
		ColorEntry(
			userDefaultsValue: UserDefaultsValueCase.strawberry.rawValue,
			displayName: LocalizedString.strawberry,
			uiColor: UIColor.systemPink),
		ColorEntry(
			userDefaultsValue: UserDefaultsValueCase.tangerine.rawValue,
			displayName: LocalizedString.tangerine,
			uiColor: UIColor.systemOrange),
		ColorEntry(
			userDefaultsValue: UserDefaultsValueCase.lime.rawValue,
			displayName: LocalizedString.lime,
			uiColor: UIColor.systemGreen),
		
		defaultColorEntry,
		
		ColorEntry(
			userDefaultsValue: UserDefaultsValueCase.grape.rawValue,
			displayName: LocalizedString.grape,
			uiColor: UIColor.systemPurple),
	]
	
	// MARK: - Restoring and Setting
	
	static func restoreAccentColor(in window: UIWindow?) {
		let colorEntryToSet = Self.savedOrDefaultColorEntry()
		Self.setAccentColor(colorEntryToSet, in: window)
	}
	
	static func setAccentColor(_ colorEntry: ColorEntry, in window: UIWindow?) {
		window?.tintColor = colorEntry.uiColor // This doesn't trigger tintColorDidChange() on LibraryTVC's table view, so we'll post our own notification.
		NotificationCenter.default.post(
			Notification(name: Notification.Name.LRDidChangeAccentColor)
		)
		
		UserDefaults.standard.set(
			colorEntry.userDefaultsValue,
			forKey: LRUserDefaultsKey.accentColorName.rawValue)
	}
	
	// MARK: - Getting Info
	
	static func savedUserDefaultsValue() -> String? {
		return UserDefaults.standard.value(
			forKey: LRUserDefaultsKey.accentColorName.rawValue) as? String
	}
	
	static func heartEmojiMatchingSavedAccentColor() -> String {
		let savedValueCase = savedUserDefaultsValueCase()
		switch savedValueCase {
		case .strawberry:
			return "❤️"
		case .tangerine:
			return "🧡"
		case .lime:
			return "💚"
		case .grape:
			return "💜"
			
		default:
			return "💙"
		}
	}
	
	// MARK: - Private Methods
	
	private init() { }
	
	private static func savedOrDefaultColorEntry() -> ColorEntry {
		// If there's a saved preference, set it.
		if
			let savedUserDefaultsValue = savedUserDefaultsValue(),
			let savedColorEntry = colorEntries.first(where: { colorEntry in
				colorEntry.userDefaultsValue == savedUserDefaultsValue
			})
		{
			return savedColorEntry
		} else { // There was no saved preference, or it didn't match any ColorEntry.
			return defaultColorEntry
		}
	}
	
	private static func savedUserDefaultsValueCase() -> UserDefaultsValueCase? {
		let savedValue = savedUserDefaultsValue()
		return Self.userDefaultsValueCase(withRawValue: savedValue)
	}
	
	private static func userDefaultsValueCase(withRawValue stringToMatch: String?) -> UserDefaultsValueCase? {
		for enumCase in UserDefaultsValueCase.allCases {
			if enumCase.rawValue == stringToMatch {
				return enumCase
			}
		}
		return nil
	}
	
}
