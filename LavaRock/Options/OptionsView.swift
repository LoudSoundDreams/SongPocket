//
//  OptionsView.swift
//  LavaRock
//
//  Created by h on 2022-01-15.
//

import SwiftUI

struct OptionsView: View {
	@Environment(\.dismiss) private var dismiss
	
	@ObservedObject private var theme: Theme
	@ObservedObject private var tipJarViewModel: TipJarViewModel
	
	init() {
		theme = .shared
		tipJarViewModel = .shared
		
		if tipJarViewModel.status == .notYetFirstLoaded {
			PurchaseManager.shared.requestTipProduct()
		}
	}
	
	var body: some View {
		NavigationView {
			Form {
				
				Section(LRString.theme) {
					Picker("", selection: $theme.lighting) {
						ForEach(Lighting.allCases) { lighting in
							lighting.image
								.accessibilityLabel(lighting.name)
								.tag(lighting)
						}
					}
					.pickerStyle(.segmented)
					
					Picker(selection: $theme.accentColor) {
						ForEach(AccentColor.allCases) { accentColor in
							Text(accentColor.displayName)
								.foregroundColor(accentColor.color)
								.tag(accentColor)
						}
					} label: { EmptyView() }
//					.pickerStyle(.inline)
					.pickerStyle(.wheel)
				}
				
				Section {
					switch tipJarViewModel.status {
					case .notYetFirstLoaded, .loading:
						Text(LRString.loadingEllipsis)
							.foregroundColor(.secondary)
					case .reload:
						Button {
							PurchaseManager.shared.requestTipProduct()
						} label: {
							Text(LRString.reload)
								.foregroundColor(theme.accentColor.color) // Don’t use the `.accentColor` modifier, because SwiftUI applies “Increase Contrast” twice.
						}
					case .ready:
						Button {
							PurchaseManager.shared.buyTip()
						} label: {
							HStack {
								Text("tip")
									.foregroundColor(theme.accentColor.color) // Don’t use the `.accentColor` modifier, because SwiftUI applies “Increase Contrast” twice.
								Spacer()
								Text("0¢")
									.foregroundColor(.secondary)
							}
						}
					case .confirming:
						Text(LRString.confirmingEllipsis)
							.foregroundColor(.secondary)
					case .thankYou:
						HStack {
							Spacer()
							Text(thankYouMessage())
								.foregroundColor(.secondary)
							Spacer()
						}
					}
				} header: {
					Text(LRString.tipJar)
				} footer: {
					Text(LRString.tipJarFooter)
				}
				
			}
			.navigationTitle(LRString.options)
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button(LRString.done) { dismiss() }
				}
			}
		}
		.navigationViewStyle(.stack)
		.tint(theme.accentColor.color) // Without this, SwiftUI applies “Increase Contrast” twice.
	}
	
	private func thankYouMessage() -> String {
		let heartEmoji = theme.accentColor.heartEmoji
		return heartEmoji + LRString.tipThankYouMessageWithPaddingSpaces + heartEmoji
	}
}
