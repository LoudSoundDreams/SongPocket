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
	case sailboat
	case beachUmbrella
	
	static var preference: Self {
		get {
			defaults.register(defaults: [persistentKey: speaker.persistentValue])
			let savedValue = defaults.string(forKey: persistentKey)!
			return allCases.first { avatarCase in
				savedValue == avatarCase.persistentValue
			}!
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
			case .speaker:
				return "speaker.fill"
			case .bird:
				return "bird"
			case .fish:
				return "fish"
			case .sailboat:
				return "sailboat"
			case .beachUmbrella:
				return "beach.umbrella"
		}
	}
	
	var playingSFSymbolName: String {
		switch self {
			case .speaker:
				return "speaker.wave.2.fill"
			case .bird:
				return "bird.fill"
			case .fish:
				return "fish.fill"
			case .sailboat:
				return "sailboat.fill"
			case .beachUmbrella:
				return "beach.umbrella.fill"
		}
	}
	
	var accessibilityLabel: String {
		switch self {
			case .speaker:
				return LRString.speaker
			case .bird:
				return LRString.bird
			case .fish:
				return LRString.fish
			case .sailboat:
				return LRString.sailboat
			case .beachUmbrella:
				return LRString.beachUmbrella
		}
	}
	
	// MARK: - Private
	
	private static let defaults: UserDefaults = .standard
	private static let persistentKey: String = LRUserDefaultsKey.avatar.rawValue
	
	private var persistentValue: String {
		switch self {
			case .speaker:
				return "Speaker"
			case .bird:
				return "Bird"
			case .fish:
				return "Fish"
			case .sailboat:
				return "Sailboat"
			case .beachUmbrella:
				return "Beach umbrella"
		}
	}
}
