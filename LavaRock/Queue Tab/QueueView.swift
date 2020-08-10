//
//  QueueView.swift
//  LavaRock
//
//  Created by h on 2020-07-26.
//

import SwiftUI

struct QueueView: View {
	static let noSongsPlaceholderText = "No Songs"
	
	@State var isPlaying = false
	@State var songs = [String]()
	
	var body: some View {
		NavigationView {
			if #available(iOS 14.0, *) {
				Text(Self.noSongsPlaceholderText)
					.font(.title)
					.foregroundColor(Color(UIColor.placeholderText))
					.multilineTextAlignment(.center)
					.navigationTitle(
						Text("Queue")
					)
					.padding()
					.navigationBarTitleDisplayMode(.inline)
					.toolbar {
						ToolbarItem(placement: .navigationBarLeading) {
							Button(action: {
								
							} ) {
								Text("Clear")
							}
						}
						ToolbarItem(placement: .bottomBar) {
							HStack {
//								Spacer()
								Button(action: {
									
								} ) {
									Image(systemName: "gobackward.10")
								}
//								Spacer()
								Button(action: {
									isPlaying.toggle()
								} ) {
									if isPlaying {
										Image(systemName: "pause.fill")
									} else {
										Image(systemName: "play.fill")
									}
								}
								.padding()
//								Spacer()
								Button(action: {
									
								} ) {
									Image(systemName: "goforward.10")
								}
//								Spacer()
//								Button(action: {
//
//								} ) {
//									Image(systemName: "ellipsis")
//								}
							}
						}
					}
			} else { // iOS 13 and earlier
				NavigationView {
					Text(Self.noSongsPlaceholderText)
						.font(.title)
						.foregroundColor(Color(UIColor.placeholderText))
						.padding(.all)
						.navigationBarTitle("Queue", displayMode: .inline)
				}
			}
		}
	}
}

struct QueueView_Previews: PreviewProvider {
	static var previews: some View {
		QueueView()
			.environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
		
	}
}
