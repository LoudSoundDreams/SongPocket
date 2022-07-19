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
	}
	
	var body: some View {
		NavigationView {
			Form {
				Section(LRString.theme) {
					ThemePicker()
				}
				
				Section {
					TipJarView()
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
					Button(LRString.done) {
						dismiss()
					}
				}
			}
		}
		.navigationViewStyle(.stack)
		.tint(theme.accentColor.color) // Without this, SwiftUI applies “Increase Contrast” twice.
	}
}
