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
	
	static let playerScreen = 10 == 1
	static let swiftUI__PlayerScreen = playerScreen && 10 == 1
	static let jumpButtons = (10 == 1) || (playerScreen && 10 == 10)
	static let playSong = (10 == 10) || (playerScreen && 10 == 10)
	
	static let swiftUI__Options = 10 == 1
}
