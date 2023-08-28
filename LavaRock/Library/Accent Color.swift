//
//  Accent Color.swift
//  LavaRock
//
//  Created by h on 2020-07-29.
//

import UIKit

@MainActor
final class Theme: ObservableObject {
	private init() {}
	static let shared = Theme()
	
	@Published var accentColor: AccentColor = .preference {
		didSet {
			// This runs before `ObservableObject.objectWillChange` emits.
			AccentColor.preference = accentColor
		}
	}
}

extension AccentColor: Identifiable {
	var id: Self { self }
}
enum AccentColor: CaseIterable {
	case blueberry
	case grape
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
			case .tangerine:
				return LRString.tangerine
			case .lime:
				return LRString.lime
		}
	}
	
	var uiColor: UIColor {
		return UIColor(named: "synthwave")!
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
			case .tangerine:
				return "Tangerine"
			case .lime:
				return "Lime"
				/*
				 Deprecated after version 1.13.3:
				 "Strawberry"
				 */
		}
	}
}
