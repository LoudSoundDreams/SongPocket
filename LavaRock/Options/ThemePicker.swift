//
//  ThemePicker.swift
//  LavaRock
//
//  Created by h on 2022-07-19.
//

import SwiftUI

struct ThemePicker: View {
	@ObservedObject private var theme: Theme = .shared
	
	var body: some View {
		Picker(
			selection: $theme.lighting
		) {
			ForEach(Lighting.allCases) { lighting in
				lighting.image
					.accessibilityLabel(lighting.accessibilityLabel)
					.tag(lighting)
			}
		} label: {
			EmptyView()
		}
		.pickerStyle(.segmented)
		
		Picker(
			selection: $theme.accentColor
		) {
			ForEach(AccentColor.allCases) { accentColor in
				Text(accentColor.displayName)
					.foregroundColor(accentColor.color)
					.tag(accentColor)
			}
		} label: {
			EmptyView()
		}
//		.pickerStyle(.menu)
//		.pickerStyle(.inline)
//		.pickerStyle(.segmented)
		.pickerStyle(.wheel)
	}
}
