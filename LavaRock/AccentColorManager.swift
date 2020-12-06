//
//  AccentColorManager.swift
//  LavaRock
//
//  Created by h on 2020-07-29.
//

import UIKit

struct AccentColorManager {
	
	struct ColorEntry {
		let userDefaultsKey: String
		let displayName: String
		let uiColor: UIColor
	}
	
	// MARK: - Properties
	
	private static let defaultColorEntry = ColorEntry(
		userDefaultsKey: "Blueberry",
		displayName: LocalizedString.blueberry,
		uiColor: UIColor.systemBlue)
	
	static let colorEntries = [
		ColorEntry(
			userDefaultsKey: "Strawberry",
			displayName: LocalizedString.strawberry,
			uiColor: UIColor.systemPink),
		ColorEntry(
			userDefaultsKey: "Tangerine",
			displayName: LocalizedString.tangerine,
			uiColor: UIColor.systemOrange),
		ColorEntry(
			userDefaultsKey: "Lime",
			displayName: LocalizedString.lime,
			uiColor: UIColor.systemGreen),
		
		defaultColorEntry,
		
		ColorEntry(
			userDefaultsKey: "Grape",
			displayName: LocalizedString.grape,
			uiColor: UIColor.systemPurple),
	]
	
	// MARK: - Methods
	
	static func restoreAccentColor(in window: UIWindow?) {
		// If there's a saved preference, set it.
		if
			let savedAccentColorKey = savedAccentColorKey(),
			let savedColorEntry = colorEntries.first(where: { colorEntry in
				colorEntry.userDefaultsKey == savedAccentColorKey
			})
		{
			Self.setAccentColor(savedColorEntry, in: window)
		} else { // There was no saved preference, or it didn't match any ColorEntry.
			Self.setAccentColor(defaultColorEntry, in: window)
		}
	}
	
	static func savedAccentColorKey() -> String? {
		return UserDefaults.standard.value(forKey: "accentColorName") as? String
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
	
}
