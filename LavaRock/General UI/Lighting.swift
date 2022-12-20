//
//  Lighting.swift
//  LavaRock
//
//  Created by h on 2021-12-04.
//

import SwiftUI
import UIKit

extension Lighting: Identifiable {
	var id: RawValue { rawValue }
}
enum Lighting: Int, CaseIterable {
	// We persist these raw values in `UserDefaults`.
	case light = 1
	case dark = 2
	case system = 0
	
	private static let defaults: UserDefaults = .standard
	private static let defaultsKey: String = LRUserDefaultsKey.lighting.rawValue
	
	static func savedPreference() -> Self {
		let savedRawValue = defaults.integer(forKey: defaultsKey) // Returns `0` when there’s no saved value, which is `.system`, which is what we want.
		return Self(rawValue: savedRawValue)!
	}
	
	func saveAsPreference() {
		Self.defaults.set(
			rawValue,
			forKey: Self.defaultsKey)
	}
	
	init(indexInDisplayOrder: Int) {
		self = Self.allCases[indexInDisplayOrder]
	}
	
	var indexInDisplayOrder: Int {
		return Self.allCases.firstIndex { $0 == self }!
	}
	
	@MainActor
	var uiImage: UIImage {
		return UIImage(systemName: sfSymbolName)!
	}
	
	@MainActor
	var image: Image {
		return Image(systemName: sfSymbolName)
	}
	
	@MainActor
	private var sfSymbolName: String {
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
}
