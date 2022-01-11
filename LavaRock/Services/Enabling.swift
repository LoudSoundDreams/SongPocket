//
//  Enabling.swift
//  LavaRock
//
//  Created by h on 2021-10-29.
//

struct Enabling {
	private init() {}
	
	static let skipButtons = 1 == 0
	
	static let multicollection = 1 == 0
	static let multialbum = multicollection && 1 == 1
	
	static let tabBar = 1 == 0
}
