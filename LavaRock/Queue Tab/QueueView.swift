//
//  QueueView.swift
//  LavaRock
//
//  Created by h on 2020-07-26.
//

import SwiftUI

struct QueueView: View {
	@State var songs = [String]()
	@State var isPlaying = true
	
	var body: some View {
		NavigationView {
			let noSongsPlaceholder = "Add some songs from Collections. They’ll start playing here."
			if #available(iOS 14.0, *) {
				Text(noSongsPlaceholder)
					.navigationTitle(
						Text("Queue")
//							.font(.system(.headline))
					)
					.navigationBarTitleDisplayMode(.inline)
					.foregroundColor(.secondary)
					.multilineTextAlignment(.center)
					.padding()
					.toolbar {
						ToolbarItem(placement: .navigationBarLeading) {
							Button(action: {
								
							} ) {
								Text("Clear")
//									.font(.system(.body))
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
//								.buttonStyle(DefaultButtonStyle())
//								Spacer()
								Button(action: {
									
								} ) {
									Image(systemName: "goforward.10")
								}
//								Spacer()
								Button(action: {
									
								} ) {
									Image(systemName: "ellipsis")
								}
							}
						}
					}
			} else { // iOS 13 and earlier
				Text(noSongsPlaceholder)
					.navigationBarTitle("Queue", displayMode: .inline)
					.foregroundColor(.secondary)
					.multilineTextAlignment(.center)
					.padding(.all)
			}
		}
	}
}

struct QueueView_Previews: PreviewProvider {
	static var previews: some View {
		QueueView()
			
	}
}
