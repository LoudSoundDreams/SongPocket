//
//  ConsoleView.swift
//  LavaRock
//
//  Created by h on 2022-01-31.
//

import SwiftUI

struct ConsoleView: View {
    var body: some View {
		NavigationView {
			VStack {
				List {
					Text("song title")
					Text("song title")
					Text("song title")
					Text("song title")
					Text("song title")
					Text("song title")
				}
				TransportPanel()
					.padding()
			}
			.navigationTitle("Queue")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading) {
					Button("Shuffle") {
						
					}
				}
			}
		}
    }
}
