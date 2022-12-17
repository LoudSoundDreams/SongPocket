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
	
	@Published var lighting: Lighting = .savedPreference() {
		didSet {
			// This runs before `ObservableObject.objectWillChange` emits.
			lighting.saveAsPreference()
		}
	}
	@Published var accentColor: AccentColor = .savedPreference() {
		didSet {
			accentColor.saveAsPreference()
		}
	}
}
