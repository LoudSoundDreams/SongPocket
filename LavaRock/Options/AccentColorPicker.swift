//
//  AccentColorPicker.swift
//  LavaRock
//
//  Created by h on 2022-07-19.
//

import SwiftUI

struct AccentColorPicker: View {
	@ObservedObject private var theme: Theme = .shared
	
	var body: some View {
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
