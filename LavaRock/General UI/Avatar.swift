//
//  Avatar.swift
//  LavaRock
//
//  Created by h on 2022-07-30.
//

import Foundation

final class AvatarObservable: ObservableObject {
	private init() {}
	static let shared = AvatarObservable()
	
	@Published var current: Avatar = .preference {
		didSet {
			Avatar.preference = current
		}
	}
}

extension Avatar: Identifiable {
	var id: Self { self }
}
enum Avatar: CaseIterable {
	case speaker
	case bird
	case fish
	
	static var preference: Self {
		get {
			defaults.register(defaults: [persistentKey: speaker.persistentValue])
			let savedValue = defaults.string(forKey: persistentKey)!
			guard let matchingCase = allCases.first(where: { avatarCase in
				savedValue == avatarCase.persistentValue
			}) else {
				// Unrecognized persistent value
				return .speaker
			}
			return matchingCase
		}
		set {
			defaults.set(newValue.persistentValue, forKey: persistentKey)
			
			NotificationCenter.default.post(
				name: .user_changed_avatar,
				object: nil)
		}
	}
	
	var pausedSFSymbolName: String {
		switch self {
			case .speaker: return "speaker.fill"
			case .bird: return "bird"
			case .fish: return "fish"
		}
	}
	
	var playingSFSymbolName: String {
		switch self {
			case .speaker: return "speaker.wave.2.fill"
			case .bird: return "bird.fill"
			case .fish: return "fish.fill"
		}
	}
	
	var accessibilityLabel: String {
		switch self {
			case .speaker: return LRString.speaker
			case .bird: return LRString.bird
			case .fish: return LRString.fish
		}
	}
	
	// MARK: - Private
	
	private static let defaults: UserDefaults = .standard
	private static let persistentKey: String = LRUserDefaultsKey.avatar.rawValue
	
	private var persistentValue: String {
		switch self {
			case .speaker: return "Speaker"
			case .bird: return "Bird"
			case .fish: return "Fish"
				/*
				 Deprecated after version 1.11.2
				 "Sailboat"
				 "Beach umbrella"
				 */
		}
	}
}
