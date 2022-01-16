//
//  OptionsView.swift
//  LavaRock
//
//  Created by h on 2022-01-15.
//

import SwiftUI
import UIKit

struct OptionsView: View {
	var uiWindow: UIWindow
	
	@AppStorage(LRUserDefaultsKey.appearance.rawValue) private var savedAppearance = Appearance.savedPreference().rawValue
	@AppStorage(LRUserDefaultsKey.accentColorName.rawValue) private var savedAccentColor = AccentColor.savedPreference().persistentValue.rawValue
	@Environment(\.dismiss) private var dismiss
	
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
					
					Picker(selection: $savedAccentColor) {
						ForEach(AccentColor.all) { accentColor in
							Text(accentColor.displayName)
								.foregroundColor(accentColor.color)
								.tag(accentColor.persistentValue.rawValue)
						}
					} label: { EmptyView() }
					.pickerStyle(.inline)
				}
				
				Section {
					HStack {
						Text("tip")
							.foregroundColor(.accentColor)
						Spacer()
						Text("0¢")
							.foregroundColor(.secondary)
					}
				} header: {
					Text(LocalizedString.tipJar)
				} footer: {
					Text(LocalizedString.tipJarFooter)
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
		
		.onChange(of: savedAppearance) { newAppearance in
			uiWindow.overrideUserInterfaceStyle = Appearance(rawValue: newAppearance)!.uiUserInterfaceStyle
		}
		.onChange(of: savedAccentColor) { newAccentColor in
			uiWindow.tintColor = UIColor(AccentColor(persistentRawValue: newAccentColor).color)
		}
	}
}
