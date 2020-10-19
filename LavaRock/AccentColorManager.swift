//
//  AccentColorManager.swift
//  LavaRock
//
//  Created by h on 2020-07-29.
//

import UIKit

struct AccentColorManager {
	
	// MARK: - Properties
	
	static let colorTuples = [
		("Strawberry", UIColor.systemPink), // "Magenta"
//		("Red", UIColor.systemRed),
		("Tangerine", UIColor.systemOrange),
//		("Yellow", UIColor.systemYellow),
		("Lime", UIColor.systemGreen),
//		("Cyan", UIColor.systemTeal),
		("Blueberry", UIColor.systemBlue),
//		("Indigo", UIColor.systemIndigo),
		("Grape", UIColor.systemPurple), // "Violet"
//		("None", UIColor.label),
	]
	private static let defaultColorName = "Blueberry" // You need to have a tuple for this in colorTuples, or you can cause an infinite loop.
	
	// MARK: - Setting and Restoring
	
	static func restoreAccentColor(in window: UIWindow?) {
		// If there's a saved preference, set it.
		if let savedColorName = savedAccentColorName() {
			Self.setAccentColor(savedColorName, in: window)
		} else { // There was no saved preference.
			Self.setAccentColor(defaultColorName, in: window)
		}
	}
	
	static func savedAccentColorName() -> String? {
		return UserDefaults.standard.value(forKey: "accentColorName") as? String
	}
	
	static func setAccentColor(_ colorName: String, in window: UIWindow?) {
		guard let uiColor = Self.uiColor(forName: colorName) else {
			Self.setAccentColor(defaultColorName, in: window)
			return
		}
		
		window?.tintColor = uiColor // This doesn't trigger tintColorDidChange() on LibraryTVC's table view, so we'll post our own notification.
		// What if you have multiple windows open on an iPad?
		
		NotificationCenter.default.post(
			Notification(name: Notification.Name.LRDidChangeAccentColor)
		)
		
		DispatchQueue.global().async { // A tester provided a screen recording of lag sometimes between selecting a row and the sheet dismissing. They reported that this line of code fixed it. iPhone SE (2nd generation), iOS 13.5.1
			UserDefaults.standard.set(colorName, forKey: "accentColorName")
		}
	}
	
	// MARK: - Converting Between Names and Colors
	
	static func uiColor(forName lookedUpName: String) -> UIColor? {
		if let (_, matchedUIColor) = colorTuples.first(where: { (savedName, _) in
			lookedUpName == savedName
		} ) {
			return matchedUIColor
		} else {
			return nil
		}
	}
	
	static func colorName(forUIColor lookedUpUIColor: UIColor) -> String? {
		if let (matchedColorName, _) = colorTuples.first(where: { (_, savedUIColor) in
			lookedUpUIColor == savedUIColor
		} ) {
			return matchedColorName
		} else {
			return nil
		}
	}
	
	static func colorName(forIndex index: Int) -> String? {
		guard (index >= 0) && (index <= colorTuples.count - 1) else {
			return nil
		}
		return colorTuples[index].0
	}
	
	static func uiColor(forIndex index: Int) -> UIColor? {
		guard (index >= 0) && (index <= colorTuples.count - 1) else {
			return nil
		}
		return colorTuples[index].1
	}
	
}
