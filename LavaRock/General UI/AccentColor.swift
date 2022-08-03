//
//  AccentColor.swift
//  LavaRock
//
//  Created by h on 2020-07-29.
//

import SwiftUI
import UIKit

extension AccentColor: Identifiable {
	var id: RawValue { rawValue }
}
enum AccentColor: String, CaseIterable {
	// We persist these raw values in `UserDefaults`.
	case strawberry = "Strawberry"
	case tangerine = "Tangerine"
	case lime = "Lime"
	case blueberry = "Blueberry"
	case grape = "Grape"
	
	private static let defaults = UserDefaults.standard
	private static let defaultsKey = LRUserDefaultsKey.accentColor.rawValue
	
	static func savedPreference() -> Self {
		defaults.register(defaults: [defaultsKey: blueberry.rawValue])
		let savedRawValue = defaults.string(forKey: defaultsKey)!
		return Self(rawValue: savedRawValue)!
	}
	
	func saveAsPreference() {
		Self.defaults.set(
			rawValue,
			forKey: Self.defaultsKey)
	}
	
	var displayName: String {
		switch self {
		case .strawberry:
			return LRString.strawberry
		case .tangerine:
			return LRString.tangerine
		case .lime:
			return LRString.lime
		case .blueberry:
			return LRString.blueberry
		case .grape:
			return LRString.grape
		}
	}
	
	var color: Color {
		switch self {
		case .strawberry:
			return .pink
		case .tangerine:
			return .orange
		case .lime:
			return .green
		case .blueberry:
			return .blue
		case .grape:
			return .purple
		}
	}
	
	var uiColor: UIColor {
		switch self {
		case .strawberry:
			/*
			 Hue:
			 • 335 - artificially pink
			 • 350 - boring “classic red”
			 
			 Saturation:
			 • 0.80 - too desaturated
			 • 0.90 - dark mode: too garish
			 
			 Brightness:
			 • 0.75 - light mode: annoyingly dark
			 • 0.80 - dark mode: too dark
			 • 1.00 - boringly bright
			 */
			return UIColor(named: "strawberry")!
			/*
			return UIColor( // Good in light mode, bad in dark mode
				hue: 340/360, // Aiming low
				saturation: 1.00, // Aiming high
				brightness: 0.80, // Aiming low
				alpha: 1)
			return UIColor( // Good in dark mode
				hue: 340/360, // Aiming low
				saturation: 0.90, // Aiming high
				brightness: 1.00, // Aiming high
				alpha: 1)
			 */
		case .tangerine:
			/*
			 Hue:
			 • 25 - boring orange (the fruit)
			 • 35 - GOOD
			 • 40 - yellow
			 
			 Saturation:
			 • 0.75 - too desaturated
			 • 1.00 - still not garish
			 
			 Brightness:
			 • 0.90 - light mode: GOOD. dark mode: too dark
			 •
			 */
			return UIColor(named: "tangerine")!
			/*
			return UIColor( // Good in light mode, bad in dark mode
				hue: 35/360, // Aiming high
				saturation: 1.00, // Aiming high
				brightness: 0.90, // Aiming low
				alpha: 1)
			return UIColor( // Good in dark mode
				hue: 35/360, // Aiming high
				saturation: 0.90, // Aiming high
				brightness: 1.00, // Aiming high
				alpha: 1)
			 */
		case .lime:
			/*
			 Hue:
			 • 80 - browning guac
			 • 90 - annoyingly yellow
			 • 105 - distractingly yellow
			 
			 • 130 - canonical (boring) green, to me. i like yellower greens better here than bluer ones
			 • 145 - too blue
			 
			 Saturation:
			 •
			 
			 Brightness:
			 • 0.50 - light mode: annoyingly dark
			 • 0.75 - light mode: annoyingly bright
			 
			 • 0.85 - dark mode: annoyingly bright
			 */
			return UIColor(named: "lime")!
			/*
			return UIColor( // Good in light mode, bad in dark mode
				hue: 110/360, // Aiming low
				saturation: 1.00, // Aiming high
				brightness: 0.55, // Aiming low
				alpha: 1)
			return UIColor( // Good in dark mode
				hue: 110/360, // Aiming low
				saturation: 0.90, // Aiming high
				brightness: 0.80, // Aiming high
				alpha: 1)
			 */
		case .blueberry:
			/*
			 Hue:
			 • 210 - approaching cyan
			 • 215 - GOOD. a tinge of yellow
			 • 235 - approaching purple
			 
			 # For hue 215
			 
			 Saturation:
			 • 0.80 - too desaturated
			 • 0.90 - dark mode: garish at any brightness
			 
			 Brightness:
			 • 0.65 - light mode: annoyingly dark
			 • 0.90 - dark mode: too dark
			 */
			return UIColor(named: "blueberry")!
			/*
			return UIColor( // Good in light mode, bad in dark mode
				hue: 215/360, // Aiming low
				saturation: 1.00, // Aiming high
				brightness: 0.75, // Aiming low
				alpha: 1)
			return UIColor( // Good in dark mode
				hue: 210/360, // Aiming low
				saturation: 0.90, // Aiming high
				brightness: 1.00, // Aiming high
				alpha: 1)
			 */
		case .grape:
			/*
			 Hue:
			 • 280 - boring lavender
			 
			 • 315 - too close to Strawberry
			 • 325 - approaching maroon or pink
			 
			 Saturation:
			 • 0.60 - too desaturated
			 • 0.90 - dark mode: too garish
			 
			 Brightness:
			 • 0.60 - light mode: nice and dark, barely different from black
			 
			 • 0.70 - dark mode: too dark
			 
			 • 0.95 - light mode: annoyingly bright. dark mode: boringly bright
			 */
			return UIColor(named: "grape")!
			/*
			return UIColor( // Good in light mode, bad in dark mode
				hue: 310/360, // Aiming high
				saturation: 1.00, // Aiming high
				brightness: 0.65, // Aiming low
				alpha: 1)
			return UIColor( // Good in dark mode
				hue: 310/360, // Aiming high
				saturation: 0.90, // Aiming high
				brightness: 0.90, // Aiming high
				alpha: 1)
			 */
		}
	}
	
	func thankYouMessage() -> String {
		return heartEmoji + LRString.tipThankYouMessageWithPaddingSpaces + heartEmoji
	}
	
	private var heartEmoji: String {
		switch self {
		case .strawberry:
			return "❤️"
		case .tangerine:
			return "🧡"
		case .lime:
			return "💚"
		case .blueberry:
			return "💙"
		case .grape:
			return "💜"
		}
	}
}
