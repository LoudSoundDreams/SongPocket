//
//  Theme.swift
//  LavaRock
//
//  Created by h on 2022-05-14.
//

import Combine

@MainActor
final class Theme: ObservableObject {
	private init() {}
	static let shared = Theme()
	
	@Published var lighting: Lighting = .preference {
		didSet {
			// This runs before `ObservableObject.objectWillChange` emits.
			Lighting.preference = lighting
		}
	}
	@Published var accentColor: AccentColor = .savedPreference() {
		didSet {
			accentColor.saveAsPreference()
		}
	}
}
