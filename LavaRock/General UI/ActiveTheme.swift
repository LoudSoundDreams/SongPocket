//
//  ActiveTheme.swift
//  LavaRock
//
//  Created by h on 2022-01-23.
//

import Combine
import SwiftUI

final class ActiveTheme: ObservableObject {
	private init() {}
	static let shared = ActiveTheme()
	
	@Published var appearance: Appearance = .savedPreference()
	@Published var accentColor: AccentColor = .savedPreference()
}
