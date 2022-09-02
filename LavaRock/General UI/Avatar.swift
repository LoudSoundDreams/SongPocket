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
	let value: String
	
	static let all: [Self] = [
		Self.speaker,
		Avatar(
			pausedSFSymbolName: "bird",
			playingSFSymbolName: "bird.fill",
			value: "Bird"),
		Avatar(
			pausedSFSymbolName: "fish",
			playingSFSymbolName: "fish.fill",
			value: "Fish"),
		Avatar(
			pausedSFSymbolName: "sailboat",
			playingSFSymbolName: "sailboat.fill",
			value: "Sailboat"),
		Avatar(
			pausedSFSymbolName: "beach.umbrella",
			playingSFSymbolName: "beach.umbrella.fill",
			value: "Beach umbrella"),
	]
	private static var speaker: Self = Avatar(
		pausedSFSymbolName: "speaker.fill",
		playingSFSymbolName: "speaker.wave.2.fill",
		value: "Speaker")
	
	static var current: Self {
		get {
			defaults.register(defaults: [key: speaker.value])
			let savedValue = defaults.string(forKey: key)
			return all.first { availableAvatar in
				savedValue == availableAvatar.value
			}!
		}
		set {
			defaults.set(newValue.value, forKey: key)
			
			NotificationCenter.default.post(
				name: .user_changed_avatar,
				object: nil)
		}
	}
	private static let defaults: UserDefaults = .standard
	private static let key: String = LRUserDefaultsKey.avatar.rawValue
}
extension Avatar: Equatable {}
