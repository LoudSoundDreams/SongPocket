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
	static let ps_swiftUI = playerScreen && 10 == 1
	static let jumpButtons = (10 == 1) || (playerScreen && 10 == 10)
	
	static let swiftUIOptions = 10 == 1
}
