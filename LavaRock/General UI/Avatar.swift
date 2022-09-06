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
	let persistentValue: String
	var displayName: String {
		return persistentValue
	}
	
	static let all: [Self] = [
		Self.speaker,
		Avatar(
			pausedSFSymbolName: "bird",
			playingSFSymbolName: "bird.fill",
			persistentValue: "Bird"),
		Avatar(
			pausedSFSymbolName: "fish",
			playingSFSymbolName: "fish.fill",
			persistentValue: "Fish"),
		Avatar(
			pausedSFSymbolName: "sailboat",
			playingSFSymbolName: "sailboat.fill",
			persistentValue: "Sailboat"),
		Avatar(
			pausedSFSymbolName: "beach.umbrella",
			playingSFSymbolName: "beach.umbrella.fill",
			persistentValue: "Beach umbrella"),
	]
	private static var speaker: Self = Avatar(
		pausedSFSymbolName: "speaker.fill",
		playingSFSymbolName: "speaker.wave.2.fill",
		persistentValue: "Speaker")
	
	static var current: Self {
		get {
			defaults.register(defaults: [persistentKey: speaker.persistentValue])
			let savedValue = defaults.string(forKey: persistentKey)
			return all.first { availableAvatar in
				savedValue == availableAvatar.persistentValue
			}!
		}
		set {
			defaults.set(newValue.persistentValue, forKey: persistentKey)
			
			NotificationCenter.default.post(
				name: .user_changed_avatar,
				object: nil)
		}
	}
	private static let defaults: UserDefaults = .standard
	private static let persistentKey: String = LRUserDefaultsKey.avatar.rawValue
}
extension Avatar: Equatable {}
