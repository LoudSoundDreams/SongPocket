//
//  TransportPanel.swift
//  LavaRock
//
//  Created by h on 2022-04-02.
//

import SwiftUI
import MediaPlayer

private extension View {
	func disabled(whenNil optional: Optional<Any>) -> some View {
		disabled(optional == nil)
	}
}

struct TransportPanel: View {
	@ObservedObject private var tapeDeckStatus: TapeDeckStatus = .shared
	private var controller: MPMusicPlayerController? { TapeDeck.shared.player }
	var body: some View {
		VStack(
			spacing: .eight * 4
		) {
			HStack(
				alignment: .firstTextBaseline
			) {
				previousSongButton
				Spacer()
				skipBackButton
				Spacer()
				rewindButton
				Spacer()
				skipForwardButton
				Spacer()
				nextSongButton
			}
			
			playPauseButton
		}
		.frame(
			height: 275,
			alignment: .top)
	}
	
	private var shuffleButton: some View {
		Button {
		} label: {
			Image(systemName: "shuffle.circle")
				.font(.system(size: .eight * 4))
		}
		.disabled(whenNil: tapeDeckStatus.current)
	}
	
	private var previousSongButton: some View {
		Button {
			controller?.skipToPreviousItem()
		} label: {
			Image(systemName: "backward.end.circle")
				.font(.system(size: .eight * 4))
		}
		.disabled(whenNil: tapeDeckStatus.current)
	}
	private var rewindButton: some View {
		Button {
			controller?.skipToBeginning()
		} label: {
			Image(systemName: "arrow.counterclockwise.circle")
				.font(.system(size: .eight * 4))
		}
		.disabled(whenNil: tapeDeckStatus.current)
	}
	private var skipBackButton: some View {
		Button {
			controller?.currentPlaybackTime -= 15
		} label: {
			Image(systemName: "gobackward.15")
				.font(.system(size: .eight * 4))
		}
		.disabled(whenNil: tapeDeckStatus.current)
	}
	
	private var playPauseButton: some View {
		Button {
			guard let status = tapeDeckStatus.current else { return }
			if status.isPlaying {
				controller?.pause()
			} else {
				controller?.play()
			}
		} label: {
			if
				let status = tapeDeckStatus.current,
				status.isPlaying
			{
				Image(systemName: "pause.circle")
					.font(.system(size: .eight * 6))
			} else {
				Image(systemName: "play.circle")
					.font(.system(size: .eight * 6))
			}
		}
		.disabled(whenNil: tapeDeckStatus.current)
	}
	
	private var skipForwardButton: some View {
		Button {
			controller?.currentPlaybackTime += 15
		} label: {
			Image(systemName: "goforward.15")
				.font(.system(size: .eight * 4))
		}
		.disabled(whenNil: tapeDeckStatus.current)
	}
	private var nextSongButton: some View {
		Button {
			controller?.skipToNextItem()
		} label: {
			Image(systemName: "forward.end.circle")
				.font(.system(size: .eight * 4))
		}
		.disabled(whenNil: tapeDeckStatus.current)
	}
}
