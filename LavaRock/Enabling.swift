//
//  Enabling.swift
//  LavaRock
//
//  Created by h on 2021-10-29.
//

struct Enabling {
	private init() {}
	
	static let multicollection = 10 == 1
	static let multialbum = multicollection && 10 == 10
	
	static let songDotDotDot = 10 == 1
	
	static let console = 10 == 1
	static let transportToolbar = (
		console
		? 10 == 10
		: true
	)
	static let consoleInToolbar = console && transportToolbar && 10 == 10
	static let optionsInTabBar = console && !transportToolbar && 10 == 1
	static let swiftUI__console = console && 10 == 1
	
	static let swiftUI__options = 10 == 1
}
