//
//  AvatarPicker.swift
//  LavaRock
//
//  Created by h on 2022-12-29.
//

import SwiftUI

struct AvatarPicker: View {
	@ObservedObject private var avatarObservable: AvatarObservable = .shared
	private static var hasEverSaved: String {
		LRUserDefaultsKey.hasSavedDatabase.rawValue
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
