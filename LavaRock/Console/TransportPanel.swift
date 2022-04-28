//
//  TransportPanel.swift
//  LavaRock
//
//  Created by h on 2022-04-02.
//

import SwiftUI
import MediaPlayer

struct TransportPanel: View {
	@ObservedObject private var tapeDeckDisplay: TapeDeckDisplay
	init() {
		tapeDeckDisplay = .shared
	}
	
	private var player: MPMusicPlayerController? { TapeDeck.shared.player }
	var body: some View {
		VStack {
			HStack {
				Button {
					player?.skipToPreviousItem()
				} label: {
					Image(systemName: "arrowtriangle.up.circle")
						.font(.system(size: .eight * 4))
				}
				Spacer()
				Button {
					player?.skipToBeginning()
				} label: {
					Image(systemName: "arrow.counterclockwise.circle")
						.font(.system(size: .eight * 4))
				}
				Spacer()
				Button {
					player?.skipToNextItem()
				} label: {
					Image(systemName: "arrowtriangle.down.circle")
						.font(.system(size: .eight * 4))
				}
			}
			Spacer(minLength: .eight * 4)
			HStack {
				Button {
					player?.currentPlaybackTime -= 10
				} label: {
					Image(systemName: "gobackward.10")
						.font(.system(size: .eight * 4))
				}
				Spacer()
				Button {
					guard let status = tapeDeckDisplay.currentStatus else { return }
					if status.isInPlayMode {
						player?.pause()
					} else {
						player?.play()
					}
				} label: {
					if
						let status = tapeDeckDisplay.currentStatus,
						status.isInPlayMode
					{
						Image(systemName: "circle")
							.font(.system(size: .eight * 8))
					} else {
						Image(systemName: "circle.fill")
							.font(.system(size: .eight * 8))
					}
				}
				Spacer()
				Button {
					player?.currentPlaybackTime += 10
				} label: {
					Image(systemName: "goforward.10")
						.font(.system(size: .eight * 4))
				}
			}
		}
		.padding([.top, .bottom], .eight * 6)
		.disabled(tapeDeckDisplay.currentStatus == nil)
	}
}
