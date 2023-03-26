//
//  Lighting.swift
//  LavaRock
//
//  Created by h on 2021-12-04.
//

import SwiftUI
import UIKit

extension Lighting: Identifiable {
	var id: Self { self }
}
enum Lighting: CaseIterable {
	case light
	case dark
	case system
	
	static var preference: Self {
		get {
			defaults.register(defaults: [persistentKey: system.persistentValue])
			let savedValue = defaults.integer(forKey: persistentKey) // Note: `UserDefaults.integer` returns `0` when there’s no saved value, which only coincidentally matches `Lighting.system.persistentValue`.
			return allCases.first { lightingCase in
				savedValue == lightingCase.persistentValue
			}!
		}
		set {
			defaults.set(newValue.persistentValue, forKey: persistentKey)
		}
	}
	
	var sfSymbolName: String {
		switch self {
			case .light:
				return "sun.max.fill"
			case .dark:
				return "moon.fill"
			case .system:
				let idiom = UIDevice.current.userInterfaceIdiom
				switch idiom {
					case .unspecified:
						return "iphone"
					case .phone:
						return "iphone"
					case .pad:
						return "ipad"
					case .tv:
						return "tv"
					case .carPlay:
						return "iphone"
					case .mac:
						return "desktopcomputer"
					@unknown default:
						return "iphone"
				}
		}
	}
	
	var colorScheme: ColorScheme? {
		switch self {
			case .light:
				return .light
			case .dark:
				return .dark
			case .system:
				return nil
		}
	}
	
	var accessibilityLabel: String {
		switch self {
			case .light:
				return LRString.light
			case .dark:
				return LRString.dark
			case .system:
				return LRString.system
		}
	}
	
	// MARK: - Private
	
	private static let defaults: UserDefaults = .standard
	private static let persistentKey: String = LRUserDefaultsKey.lighting.rawValue
	
	private var persistentValue: Int {
		switch self {
			case .light:
				return 1
			case .dark:
				return 2
			case .system:
				return 0
		}
	}
}
