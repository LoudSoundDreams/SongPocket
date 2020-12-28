//
//  AccentColorManager.swift
//  LavaRock
//
//  Created by h on 2020-07-29.
//

import UIKit

struct AccentColorManager {
	
	// MARK: - Types
	
	private enum UserDefaultsKey: String, CaseIterable {
		case strawberry = "Strawberry"
		case tangerine = "Tangerine"
		case lime = "Lime"
		case blueberry = "Blueberry"
		case grape = "Grape"
	}
	
	struct ColorEntry {
		let userDefaultsKey: String
		let displayName: String
		let uiColor: UIColor
	}
	
	// MARK: - Properties
	
	private static let defaultColorEntry = ColorEntry(
		userDefaultsKey: UserDefaultsKey.blueberry.rawValue,
		displayName: LocalizedString.blueberry,
		uiColor: UIColor.systemBlue)
	
	static let colorEntries = [
		ColorEntry(
			userDefaultsKey: UserDefaultsKey.strawberry.rawValue,
			displayName: LocalizedString.strawberry,
			uiColor: UIColor.systemPink),
		ColorEntry(
			userDefaultsKey: UserDefaultsKey.tangerine.rawValue,
			displayName: LocalizedString.tangerine,
			uiColor: UIColor.systemOrange),
		ColorEntry(
			userDefaultsKey: UserDefaultsKey.lime.rawValue,
			displayName: LocalizedString.lime,
			uiColor: UIColor.systemGreen),
		
		defaultColorEntry,
		
		ColorEntry(
			userDefaultsKey: UserDefaultsKey.grape.rawValue,
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
		
		DispatchQueue.global().async { // A tester provided a screen recording of lag sometimes between selecting a row and the sheet dismissing. They reported that this line of code fixed it. iPhone SE (2nd generation), iOS 13.5.1
			UserDefaults.standard.set(colorEntry.userDefaultsKey, forKey: "accentColorName")
		}
	}
	
	// MARK: - Getting Info
	
	static func savedUserDefaultsKey() -> String? {
		return UserDefaults.standard.value(forKey: "accentColorName") as? String
	}
	
	static func heartEmojiMatchingSavedAccentColor() -> String {
		let savedKey = enumCaseForSavedUserDefaultsKey()
		switch savedKey {
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
	
	private static func savedOrDefaultColorEntry() -> ColorEntry {
		// If there's a saved preference, set it.
		if
			let savedUserDefaultsKey = savedUserDefaultsKey(),
			let savedColorEntry = colorEntries.first(where: { colorEntry in
				colorEntry.userDefaultsKey == savedUserDefaultsKey
			})
		{
			return savedColorEntry
		} else { // There was no saved preference, or it didn't match any ColorEntry.
			return defaultColorEntry
		}
	}
	
	private static func enumCaseForSavedUserDefaultsKey() -> UserDefaultsKey? {
		let key = savedUserDefaultsKey()
		return Self.enumCase(forUserDefaultsKey: key)
	}
	
	private static func enumCase(forUserDefaultsKey stringToMatch: String?) -> UserDefaultsKey? {
		for enumCase in UserDefaultsKey.allCases {
			if enumCase.rawValue == stringToMatch {
				return enumCase
			}
		}
		return nil
	}
	
}
