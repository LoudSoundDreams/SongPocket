//
//  AccentColorManager.swift
//  LavaRock
//
//  Created by h on 2020-07-29.
//

import UIKit

struct AccentColorManager {
	
	// MARK: Properties
	
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
	
	// MARK: Methods
	
	static func setAccentColor(_ window: UIWindow) {
		
		// If there's a saved accent color preference, set it.
		if
			let savedAccentColorName = UserDefaults.standard.value(forKey: "accentColorName") as? String,
			let matchedAccentColor = Self.uiColor(forName: savedAccentColorName)
		{
			window.tintColor = matchedAccentColor // What if you have multiple windows open on an iPad?
			
		} else { // Otherwise, either there was no saved preference, or there was one but it didn't correspond to any UIColor in AccentColorManager. Set and save the default accent color.
			window.tintColor = UIColor.systemBlue
			if let defaultAccentColorName = Self.colorName(forUIColor: window.tintColor) {
				DispatchQueue.global().async {
					UserDefaults.standard.setValue(defaultAccentColorName, forKey: "accentColorName")
				}
			}
		}
		
	}
	
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
