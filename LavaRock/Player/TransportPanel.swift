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
	
	private let eight: CGFloat = 8
	private var player: MPMusicPlayerController? { PlayerWatcher.shared.player }
	var body: some View {
		VStack(spacing: 0) {
			
			HStack {
				Button {
					player?.skipToPreviousItem()
				} label: {
					Image(systemName: "arrowtriangle.up.circle")
						.font(.system(size: eight * 4))
				}
				Spacer()
				Button {
					player?.skipToNextItem()
				} label: {
					Image(systemName: "arrowtriangle.down.circle")
						.font(.system(size: eight * 4))
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
						.font(.system(size: eight * 12))
				} else {
					Image(systemName: "circle.fill")
						.font(.system(size: eight * 12))
				}
			}
			
			HStack {
				Button {
					player?.currentPlaybackTime -= 10
				} label: {
					Image(systemName: "gobackward.10")
						.font(.system(size: eight * 4))
				}
				Spacer()
				Button {
					player?.currentPlaybackTime += 10
				} label: {
					Image(systemName: "goforward.10")
						.font(.system(size: eight * 4))
				}
			}
			
		}
		.disabled(playerStatusBoard.currentStatus == nil)
    }
}
