//
//  Avatar - Setting.swift
//  LavaRock
//
//  Created by h on 2022-07-30.
//

import SwiftUI

// MARK: - Setting

final class AvatarObservable: ObservableObject {
	private init() {}
	static let shared = AvatarObservable()
	
	@Published var current: Avatar = .preference {
		didSet {
			Avatar.preference = current
		}
	}
}

struct AvatarPicker: View {
	@ObservedObject private var avatarObservable: AvatarObservable = .shared
	private static var hasEverSaved: String {
		DefaultsKey.hasSavedDatabase.rawValue
	}
	@AppStorage(Self.hasEverSaved)
	private var hasSaved: Bool = UserDefaults.standard.bool(forKey: Self.hasEverSaved)
	
	var body: some View {
		Picker("", selection: $avatarObservable.current) {
			ForEach(Avatar.allCases) { avatar in
				Image(systemName: avatar.playingSFSymbolName)
					.accessibilityLabel(avatar.accessibilityLabel)
			}
		}
		.pickerStyle(.segmented)
		.disabled({
			return !hasSaved
		}())
	}
}
struct AvatarPicker_Previews: PreviewProvider {
	static var previews: some View {
		AvatarPicker()
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
	case luxo
	
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
			case .luxo: return "lamp.desk"
		}
	}
	
	var playingSFSymbolName: String {
		switch self {
			case .speaker: return "speaker.wave.2.fill"
			case .pawprint: return "pawprint.fill"
			case .fish: return "fish.fill"
			case .luxo: return "lamp.desk.fill"
		}
	}
	
	var accessibilityLabel: String {
		switch self {
			case .speaker: return LRString.speaker
			case .pawprint: return LRString.pawprint
			case .fish: return LRString.fish
			case .luxo: return LRString.luxoLamp
		}
	}
	
	// MARK: Private
	
	private static let defaults: UserDefaults = .standard
	private static let persistentKey: String = DefaultsKey.avatar.rawValue
	
	private var persistentValue: String {
		switch self {
			case .speaker: return "Speaker"
			case .pawprint: return "Paw" // Introduced after version 1.11.2
			case .fish: return "Fish"
			case .luxo: return "Luxo" // Introduced after version 1.11.2
				/*
				 Deprecated after version 1.11.2:
				 "Bird"
				 "Sailboat"
				 "Beach umbrella"
				 */
		}
	}
}