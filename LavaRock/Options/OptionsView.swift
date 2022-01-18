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
	
	@AppStorage(LRUserDefaultsKey.appearance.rawValue)
	private var savedAppearance = Appearance.savedPreference().rawValue
	@AppStorage(LRUserDefaultsKey.accentColor.rawValue)
	private var savedAccentColor = AccentColor.savedPreference().rawValue
	@Environment(\.dismiss)
	private var dismiss
	
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
						ForEach(AccentColor.allCases) { accentColor in
							Text(accentColor.displayName)
								.foregroundColor(Color(accentColor.uiColor))
								.tag(accentColor.rawValue)
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
		
		.onChange(of: savedAppearance) { newValue in
			let appearance = Appearance(rawValue: newValue)!
			uiWindow.overrideUserInterfaceStyle = appearance.uiUserInterfaceStyle
		}
		.onChange(of: savedAccentColor) { newValue in
			let accentColor = AccentColor(rawValue: newValue)!
			uiWindow.tintColor = accentColor.uiColor
		}
	}
}
