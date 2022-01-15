//
//  OptionsView.swift
//  LavaRock
//
//  Created by h on 2022-01-15.
//

import SwiftUI

struct OptionsView: View {
	@Environment(\.dismiss) private var dismiss
	@AppStorage(LRUserDefaultsKey.appearance.rawValue) private var savedAppearance = Appearance.savedPreference().rawValue
	var uiWindow: UIWindow
	
	var body: some View {
		NavigationView {
			Form {
				
				Section(LocalizedString.theme) {
					Picker("", selection: $savedAppearance) {
						ForEach(Appearance.allCases) { appearance in
							Image(systemName: appearance.sfSymbolName)
								.accessibilityLabel(appearance.name)
								.tag(appearance.rawValue)
						}
					}
					.pickerStyle(.segmented)
					
					Text("accent color")
				}
				
				Section(LocalizedString.tipJar) {
					Text("tip")
				}
				
			}
			.navigationTitle(LocalizedString.options)
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button(LocalizedString.done) { dismiss() }
				}
			}
		}
		.navigationViewStyle(.stack)
		
		.onChange(of: savedAppearance) { newSavedAppearance in
			uiWindow.overrideUserInterfaceStyle = Appearance(rawValue: newSavedAppearance)!.uiUserInterfaceStyle
		}
	}
}
