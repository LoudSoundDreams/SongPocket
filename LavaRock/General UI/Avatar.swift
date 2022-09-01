//
//  Avatar.swift
//  LavaRock
//
//  Created by h on 2022-07-30.
//

import Foundation

extension Notification.Name {
	static var user_changed_avatar: Self {
		Self("user changed avatar")
	}
}

struct Avatar {
	let pausedSFSymbolName: String
	let playingSFSymbolName: String
	
	static var current: Self = Avatar(
		pausedSFSymbolName: "speaker.fill",
		playingSFSymbolName: "speaker.wave.2.fill")
	
	static let all: [Self] = [
		Avatar(
			pausedSFSymbolName: "speaker.fill",
			playingSFSymbolName: "speaker.wave.2.fill"),
		Avatar(
			pausedSFSymbolName: "bird",
			playingSFSymbolName: "bird.fill"),
		Avatar(
			pausedSFSymbolName: "fish",
			playingSFSymbolName: "fish.fill"),
		Avatar(
			pausedSFSymbolName: "sailboat",
			playingSFSymbolName: "sailboat.fill"),
		Avatar(
			pausedSFSymbolName: "beach.umbrella",
			playingSFSymbolName: "beach.umbrella.fill"),
	]
}
