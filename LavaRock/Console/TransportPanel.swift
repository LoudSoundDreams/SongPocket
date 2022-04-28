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
		if Enabling.consoleInToolbar {
			HStack {
				previousSongButton
					.padding(.trailing, .eight * 4)
				rewindButton
				Spacer()
			}
			.padding([.top, .bottom], .eight * 6)
			.disabled(tapeDeckDisplay.currentStatus == nil)
		} else {
			VStack {
				HStack {
					previousSongButton
					Spacer()
					rewindButton
					Spacer()
					nextSongButton
				}
				Spacer(minLength: .eight * 4)
				HStack {
					skipBackwardButton
					Spacer()
					playPauseButton
					Spacer()
					skipForwardButton
				}
			}
			.padding([.top, .bottom], .eight * 6)
			.disabled(tapeDeckDisplay.currentStatus == nil)
		}
	}
	
	private var previousSongButton: some View {
		Button {
			player?.skipToPreviousItem()
		} label: {
			Image(systemName: "backward.end")
				.font(.system(size: .eight * 4))
		}
	}
	
	private var rewindButton: some View {
		Button {
			player?.skipToBeginning()
		} label: {
			Image(systemName: "arrow.counterclockwise")
				.font(.system(size: .eight * 4))
		}
	}
	
	private var skipBackwardButton: some View {
		Button {
			player?.currentPlaybackTime -= 10
		} label: {
			Image(systemName: "gobackward.10")
				.font(.system(size: .eight * 4))
		}
	}
	
	private var playPauseButton: some View {
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
	}
	
	private var skipForwardButton: some View {
		Button {
			player?.currentPlaybackTime += 10
		} label: {
			Image(systemName: "goforward.10")
				.font(.system(size: .eight * 4))
		}
	}
	
	private var nextSongButton: some View {
		Button {
			player?.skipToNextItem()
		} label: {
			Image(systemName: "forward.end")
				.font(.system(size: .eight * 4))
		}
	}
}
