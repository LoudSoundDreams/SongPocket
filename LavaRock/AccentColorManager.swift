//
//  AccentColorManager.swift
//  LavaRock
//
//  Created by h on 2020-07-29.
//

import UIKit

struct AccentColorManager {
	
	// MARK: - Properties
	
	static let accentColorTuples = [
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
	
	// MARK: - Setting and Restoring
	
	static func restoreOrResetAccentColor(inWindow window: UIWindow) {
		// If there's a saved preference, set it.
		if
			let savedColorName = UserDefaults.standard.value(forKey: "accentColorName") as? String,
			let matchedUIColor = Self.uiColor(forName: savedColorName)
		{
			window.tintColor = matchedUIColor // What if you have multiple windows open on an iPad?
			
		} else { // Either there was no saved preference, or there was one but it didn't correspond to any UIColor in AccentColorManager. Set and save the default accent color.
			Self.tryToSetAndSaveAccentColor("Blueberry", inWindow: window) // You need to have a tuple for this color in accentColorTuples.
		}
	}
	
	static func tryToSetAndSaveAccentColor(_ colorName: String, inWindow window: UIWindow?) {
		guard let uiColor = Self.uiColor(forName: colorName) else { return }
		window?.tintColor = uiColor
		DispatchQueue.global().async { // A tester provided a screen recording of lag sometimes between selecting a row and the sheet dismissing. They reported that this line of code fixed it. iPhone SE (2nd generation), iOS 13.5.1
			UserDefaults.standard.set(colorName, forKey: "accentColorName")
		}
	}
	
	// MARK: Converting Between Names and Colors
	
	static func uiColor(forName lookedUpName: String) -> UIColor? {
		if let (_, matchedUIColor) = accentColorTuples.first(where: { (savedName, _) in
			lookedUpName == savedName
		} ) {
			return matchedUIColor
		} else {
			return nil
		}
	}
	
	static func colorName(forUIColor lookedUpUIColor: UIColor) -> String? {
		if let (matchedColorName, _) = accentColorTuples.first(where: { (_, savedUIColor) in
			lookedUpUIColor == savedUIColor
		} ) {
			return matchedColorName
		} else {
			return nil
		}
	}
	
	static func colorName(forIndex index: Int) -> String? {
		guard (index >= 0) && (index <= accentColorTuples.count - 1) else {
			return nil
		}
		return accentColorTuples[index].0
	}
	
	static func uiColor(forIndex index: Int) -> UIColor? {
		guard (index >= 0) && (index <= accentColorTuples.count - 1) else {
			return nil
		}
		return accentColorTuples[index].1
	}
	
}
