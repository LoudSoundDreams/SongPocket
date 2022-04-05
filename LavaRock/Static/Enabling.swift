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
	
	static let iso8601Dates = 10 == 10
	
	static let playerScreen = 10 == 1
	static let swiftUI__playerScreen = playerScreen && 10 == 1
	static let jumpButtons = (10 == 1) || (playerScreen && 10 == 10)
	
	static let swiftUI__options = 10 == 1
}
