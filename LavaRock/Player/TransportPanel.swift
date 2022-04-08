//
//  TransportPanel.swift
//  LavaRock
//
//  Created by h on 2022-04-02.
//

import SwiftUI
import MediaPlayer

struct TransportPanel: View {
	@ObservedObject private var playerStatusBoard: PlayerStatusBoard
	init() {
		playerStatusBoard = .shared
	}
	
	private var player: MPMusicPlayerController? { PlayerWatcher.shared.player }
	var body: some View {
		VStack(spacing: 0) {
			
			HStack {
				Button {
					player?.skipToPreviousItem()
				} label: {
					Image(systemName: "arrowtriangle.up.circle")
						.font(.system(size: 32))
				}
				Spacer()
				Button {
					player?.skipToNextItem()
				} label: {
					Image(systemName: "arrowtriangle.down.circle")
						.font(.system(size: 32))
				}
			}
			
			Button {
				guard let status = playerStatusBoard.currentStatus else { return }
				if status.isInPlayMode {
					player?.pause()
				} else {
					player?.play()
				}
			} label: {
				if
					let status = playerStatusBoard.currentStatus,
					status.isInPlayMode
				{
					Image(systemName: "circle")
						.font(.system(size: 96))
				} else {
					Image(systemName: "circle.fill")
						.font(.system(size: 96))
				}
			}
			
			HStack {
				Button {
					player?.currentPlaybackTime -= 10
				} label: {
					Image(systemName: "gobackward.10")
						.font(.system(size: 32))
				}
				Spacer()
				Button {
					player?.currentPlaybackTime += 10
				} label: {
					Image(systemName: "goforward.10")
						.font(.system(size: 32))
				}
			}
			
		}
		.disabled(playerStatusBoard.currentStatus == nil)
    }
}
