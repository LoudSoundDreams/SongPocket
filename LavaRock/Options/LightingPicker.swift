//
//  LightingPicker.swift
//  LavaRock
//
//  Created by h on 2022-12-29.
//

import SwiftUI

struct LightingPicker: View {
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
	}
}
