//
//  OSSignposter.swift
//  LavaRock
//
//  Created by h on 2022-07-19.
//

import OSLog

extension OSSignposter {
	static let standardLibrary = OSSignposter(
		subsystem: "0. Standard Library",
		category: .pointsOfInterest)
	static let mediaPlayer = OSSignposter(
		subsystem: "1. Media Player",
		category: .pointsOfInterest)
}
