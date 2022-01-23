//
//  OptionsView.swift
//  LavaRock
//
//  Created by h on 2022-01-15.
//

import SwiftUI
import UIKit

struct OptionsView: View {
	let uiWindow: UIWindow
	@Environment(\.dismiss) private var dismiss
	
	@AppStorage(LRUserDefaultsKey.appearance.rawValue)
	private var savedAppearance = Appearance.savedPreference().rawValue
	@AppStorage(LRUserDefaultsKey.accentColor.rawValue)
	private var savedAccentColor = AccentColor.savedPreference().rawValue
	@ObservedObject private var tipJarViewModel = TipJarViewModel.shared
	
	init(uiWindow: UIWindow) {
		self.uiWindow = uiWindow
		
		if tipJarViewModel.status == .notYetFirstLoaded {
			PurchaseManager.shared.requestAllSKProducts()
		}
	}
	
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
								.foregroundColor(accentColor.color)
								.tag(accentColor.rawValue)
						}
					} label: { EmptyView() }
//					.pickerStyle(.inline)
					// TO DO: These all apply “Increase Contrast” twice.
//					.tint(.accentColor)
//					.foregroundColor(.accentColor)
//					.tint(AccentColor.savedPreference().color)
//					.foregroundColor(AccentColor.savedPreference().color)
//					.tint(Color(uiWindow.tintColor))
//					.foregroundColor(Color(uiWindow.tintColor))
					
					.pickerStyle(.wheel)
				}
				
				Section {
					switch tipJarViewModel.status {
					case .notYetFirstLoaded, .loading:
						Text(LocalizedString.loadingEllipsis).foregroundColor(.secondary)
					case .reload:
						Button {
							PurchaseManager.shared.requestAllSKProducts()
						} label: {
							Text(LocalizedString.reload).foregroundColor(AccentColor.savedPreference().color) // Don’t use `.accentColor`, because SwiftUI applies “Increase Contrast” twice.
						}
					case .ready:
						Button {
							if let tipProduct = PurchaseManager.shared.tipProduct {
								PurchaseManager.shared.addToPaymentQueue(tipProduct)
							}
						} label: {
							HStack {
								Text("tip").foregroundColor(AccentColor.savedPreference().color) // Don’t use `.accentColor`, because SwiftUI applies “Increase Contrast” twice.
								Spacer()
								Text("0¢").foregroundColor(.secondary)
							}
						}
					case .confirming:
						Text(LocalizedString.confirmingEllipsis).foregroundColor(.secondary)
					case .thankYou:
						Text(thankYouMessage()).foregroundColor(.secondary)
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
		.tint(AccentColor.savedPreference().color) // Without this, SwiftUI applies “Increase Contrast” twice.
		
		.onChange(of: savedAppearance) { newAppearance in
			let appearance = Appearance(rawValue: newAppearance)!
			uiWindow.overrideUserInterfaceStyle = appearance.uiUserInterfaceStyle
		}
		.onChange(of: savedAccentColor) { newAccentColor in
			let accentColor = AccentColor(rawValue: newAccentColor)!
			uiWindow.tintColor = accentColor.uiColor
		}
	}
	
	private func thankYouMessage() -> String {
		let heartEmoji = AccentColor.savedPreference().heartEmoji
		return heartEmoji + LocalizedString.tipThankYouMessageWithPaddingSpaces + heartEmoji
	}
}
