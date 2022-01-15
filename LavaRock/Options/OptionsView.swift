//
//  OptionsView.swift
//  LavaRock
//
//  Created by h on 2022-01-15.
//

import SwiftUI

struct OptionsView: View {
	@Environment(\.dismiss) private var dismiss
	
	var body: some View {
		NavigationView {
			List {
				Text("Options View")
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
	}
}

struct OptionsView_Previews: PreviewProvider {
	static var previews: some View {
		OptionsView()
	}
}
