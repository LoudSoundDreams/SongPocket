//
//  OptionsView.swift
//  LavaRock
//
//  Created by h on 2022-01-15.
//

import SwiftUI
import UIKit

struct OptionsView: View {
	@Environment(\.dismiss) private var dismiss
	
	@AppStorage(LRUserDefaultsKey.lighting.rawValue)
	private var savedLighting = Lighting.savedPreference().rawValue
	@AppStorage(LRUserDefaultsKey.accentColor.rawValue)
	private var savedAccentColor = AccentColor.savedPreference().rawValue
	@ObservedObject private var tipJarViewModel = TipJarViewModel.shared
	
	init() {
		if tipJarViewModel.status == .notYetFirstLoaded {
			PurchaseManager.shared.requestAllSKProducts()
		}
	}
	
	var body: some View {
		NavigationView {
			Form {
				
				Section(LocalizedString.theme) {
					Picker("", selection: $savedLighting) {
						ForEach(Lighting.allCases) { lighting in
							Image(systemName: lighting.sfSymbolName)
								.accessibilityLabel(lighting.name)
								.tag(lighting.rawValue)
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
//					.tint(ActiveTheme.shared.accentColor.color)
//					.foregroundColor(ActiveTheme.shared.accentColor.color)
					
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
						HStack {
							Spacer()
							Text(thankYouMessage()).foregroundColor(.secondary)
							Spacer()
						}
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
		
		.onChange(of: savedLighting) { newLighting in
			let lighting = Lighting(rawValue: newLighting)!
			ActiveTheme.shared.lighting = lighting
		}
		.onChange(of: savedAccentColor) { newAccentColor in
			let accentColor = AccentColor(rawValue: newAccentColor)!
			ActiveTheme.shared.accentColor = accentColor
		}
	}
	
	private func thankYouMessage() -> String {
		let heartEmoji = AccentColor.savedPreference().heartEmoji
		return heartEmoji + LocalizedString.tipThankYouMessageWithPaddingSpaces + heartEmoji
	}
}
