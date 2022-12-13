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
		return self
			.disabled(optional == nil)
	}
}

struct TransportPanel: View {
	@ObservedObject private var tapeDeckStatus: TapeDeckStatus
	init() {
		tapeDeckStatus = .shared
	}
	
	private var player: MPMusicPlayerController? { TapeDeck.shared.player }
	var body: some View {
		VStack(
			spacing: .eight * 4
		) {
			FutureChooserRep()
				.fixedSize()
			
			HStack(
				alignment: .firstTextBaseline
			) {
				previousButton
				Spacer()
				skipBackButton
				Spacer()
				rewindButton
				Spacer()
				skipForwardButton
				Spacer()
				nextButton
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
	
	private var openMusicButton: some View {
		Button {
			UIApplication.shared.open(.music)
		} label: {
			Image(systemName: "arrow.up.forward.app")
				.font(.system(size: .eight * 4))
		}
	}
	
	private var previousButton: some View {
		Button {
			player?.skipToPreviousItem()
		} label: {
			Image(systemName: "backward.end.circle")
				.font(.system(size: .eight * 4))
		}
		.disabled(whenNil: tapeDeckStatus.current)
	}
	private var rewindButton: some View {
		Button {
			player?.skipToBeginning()
		} label: {
			Image(systemName: "arrow.counterclockwise.circle")
				.font(.system(size: .eight * 4))
		}
		.disabled(whenNil: tapeDeckStatus.current)
	}
	private var skipBackButton: some View {
		Button {
			player?.currentPlaybackTime -= 15
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
				player?.pause()
			} else {
				player?.play()
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
			player?.currentPlaybackTime += 15
		} label: {
			Image(systemName: "goforward.15")
				.font(.system(size: .eight * 4))
		}
		.disabled(whenNil: tapeDeckStatus.current)
	}
	private var nextButton: some View {
		Button {
			player?.skipToNextItem()
		} label: {
			Image(systemName: "forward.end.circle")
				.font(.system(size: .eight * 4))
		}
		.disabled(whenNil: tapeDeckStatus.current)
	}
}
