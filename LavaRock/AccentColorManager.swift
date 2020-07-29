//
//  AccentColorManager.swift
//  LavaRock
//
//  Created by h on 2020-07-29.
//

import UIKit

class AccentColorManager {
	
	static let accentColorTuples = [
		("Magenta", UIColor.systemPink),
		("Red", UIColor.systemRed),
		("Orange", UIColor.systemOrange),
		("Yellow", UIColor.systemYellow),
		("Green", UIColor.systemGreen),
		("Cyan", UIColor.systemTeal),
		("Blue", UIColor.systemBlue),
		("Indigo", UIColor.systemIndigo),
		("Violet", UIColor.systemPurple),
		("None", UIColor.label),
	]
	
	static func uiColor(forName name: String) -> UIColor? {
		if let (_, matchedUIColor) = accentColorTuples.first(where: { (savedName, _) in
			name == savedName
		} ) {
			return matchedUIColor
		} else {
			return nil
		}
	}
	
}
