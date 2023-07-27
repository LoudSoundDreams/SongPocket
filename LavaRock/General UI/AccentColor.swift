//
//  AccentColor.swift
//  LavaRock
//
//  Created by h on 2020-07-29.
//

import UIKit

extension AccentColor: Identifiable {
	var id: Self { self }
}
enum AccentColor: CaseIterable {
	case blueberry
	case grape
	case strawberry
	case tangerine
	case lime
	
	static var preference: Self {
		get {
			defaults.register(defaults: [persistentKey: blueberry.persistentValue])
			let savedRawValue = defaults.string(forKey: persistentKey)!
			guard let matchingCase = allCases.first(where: { accentColorCase in
				savedRawValue == accentColorCase.persistentValue
			}) else {
				// Unrecognized persistent value
				return .blueberry
			}
			return matchingCase
		}
		set {
			defaults.set(newValue.persistentValue, forKey: persistentKey)
		}
	}
	
	var displayName: String {
		switch self {
			case .blueberry:
				return LRString.blueberry
			case .grape:
				return LRString.grape
			case .strawberry:
				return LRString.strawberry
			case .tangerine:
				return LRString.tangerine
			case .lime:
				return LRString.lime
		}
	}
	
	var heartEmoji: String {
		switch self {
			case .blueberry:
				return "💙"
			case .grape:
				return "💜"
			case .strawberry:
				return "❤️"
			case .tangerine:
				return "🧡"
			case .lime:
				return "💚"
		}
	}
	
	/*
	 BLUEBERRY
	 
	 # Light mode
	 
	 Hue (º): 210 - aiming low
	 Saturation (%): 100 - aiming high
	 Brightness (%): 60 - aiming low
	 
	 # Dark mode
	 
	 H: 200 - aiming low
	 S: 70 - aiming low
	 B: 100 - aiming high
	 
	 GRAPE
	 
	 # Light mode
	 
	 H: 310 - aiming high
	 S: 100 - aiming high
	 B: 50 - aiming low
	 
	 # Dark mode
	 
	 S: 50 - aiming low
	 B: 100 - aiming high
	 
	 STRAWBERRY
	 
	 # Light mode
	 
	 H: 340 - aiming low
	 S: 100 - aiming high
	 B: 70 - aiming low
	 
	 # Dark mode
	 
	 S: 60 - aiming low
	 B: 100 - aiming high
	 
	 TANGERINE
	 
	 # Light mode
	 
	 H: 10 - aiming low
	 S: 100 - aiming high
	 B: 75 - aiming low
	 
	 # Dark mode
	 
	 H: 40 - aiming high
	 S: 70 - aiming low
	 B: 100 - aiming high
	 
	 LIME
	 
	 # Light mode
	 
	 H: 100 - aiming low
	 S: 100 - aiming high
	 B: 40 - aiming low
	 
	 # Dark mode
	 
	 S: 50 - aiming low
	 B: 100 - aiming high
	 */
	var uiColor: UIColor {
		switch self {
			case .blueberry:
				return UIColor(named: "blueberry")!
			case .grape:
				return UIColor(named: "grape")!
			case .strawberry:
				return UIColor(named: "strawberry")!
			case .tangerine:
				return UIColor(named: "tangerine")!
			case .lime:
				return UIColor(named: "lime")!
		}
	}
	
	// MARK: - Private
	
	private static let defaults: UserDefaults = .standard
	private static let persistentKey: String = DefaultsKey.accentColor.rawValue
	
	private var persistentValue: String {
		switch self {
			case .blueberry:
				return "Blueberry"
			case .grape:
				return "Grape"
			case .strawberry:
				return "Strawberry"
			case .tangerine:
				return "Tangerine"
			case .lime:
				return "Lime"
		}
	}
}
