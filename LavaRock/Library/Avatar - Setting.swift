//
//  Avatar - Setting.swift
//  LavaRock
//
//  Created by h on 2022-07-30.
//

import SwiftUI

// MARK: - Setting

final class CurrentAvatar: ObservableObject {
	private init() {}
	static let shared = CurrentAvatar()
	
	@Published var avatar: Avatar = .preference {
		didSet {
			Avatar.preference = avatar
		}
	}
}

// MARK: - Model

extension Avatar: Identifiable {
	var id: Self { self }
}
enum Avatar: CaseIterable {
	case speaker
	case pawprint
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
			case .pawprint: return "pawprint"
			case .fish: return "fish"
		}
	}
	
	var playingSFSymbolName: String {
		switch self {
			case .speaker: return "speaker.wave.2.fill"
			case .pawprint: return "pawprint.fill"
			case .fish: return "fish.fill"
		}
	}
	
	var displayName: String {
		switch self {
			case .speaker: return LRString.speaker
			case .pawprint: return LRString.pawprint
			case .fish: return LRString.fish
		}
	}
	
	static func createAvatarAction(
		_ avatar: Avatar
	) -> UIAction {
		return UIAction(
			title: avatar.displayName,
			image: UIImage(systemName: avatar.playingSFSymbolName),
			attributes: {
				var result: UIMenu.Attributes = .keepsMenuPresented
				let hasEverSaved = UserDefaults.standard.bool(forKey: DefaultsKey.hasSavedDatabase.rawValue)
				if !hasEverSaved {
					result.formUnion(.disabled)
				}
				return result
			}()
		) { _ in
			CurrentAvatar.shared.avatar = avatar
		}
	}
	
	// MARK: Private
	
	private static let defaults: UserDefaults = .standard
	private static let persistentKey: String = DefaultsKey.avatar.rawValue
	
	private var persistentValue: String {
		switch self {
			case .speaker: return "Speaker"
			case .pawprint: return "Paw" // Introduced in version 1.12
			case .fish: return "Fish"
				/*
				 Introduced in version 1.12
				 Deprecated after version 1.13.3
				 "Luxo"
				 
				 Deprecated after version 1.11.2:
				 "Bird"
				 "Sailboat"
				 "Beach umbrella"
				 */
		}
	}
}
