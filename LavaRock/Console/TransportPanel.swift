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

private struct ChooserRep: UIViewRepresentable {
	typealias UIViewType = UISegmentedControl
	
	func makeUIView(
		context: Context
	) -> UISegmentedControl {
		return FutureChooser()
	}
	
	func updateUIView(
		_ uiView: UISegmentedControl,
		context: Context
	) {
	}
}

struct TransportPanel: View {
	@ObservedObject private var tapeDeckDisplay: TapeDeckDisplay
	init() {
		tapeDeckDisplay = .shared
	}
	
	private var player: MPMusicPlayerController? { TapeDeck.shared.player }
	var body: some View {
		VStack(
			spacing: .eight * 4
		) {
			ChooserRep()
				.fixedSize()
			
			HStack(
			) {
				previousButton
				Spacer()
				rewindButton
				Spacer()
				nextButton
			}
			
			HStack(
			) {
				skipBackButton
				Spacer()
				playPauseButton
				Spacer()
				skipForwardButton
			}
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
		.disabled(whenNil: tapeDeckDisplay.status)
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
			Image(systemName: "arrow.backward.circle")
				.font(.system(size: .eight * 4))
		}
		.disabled(whenNil: tapeDeckDisplay.status)
	}
	private var rewindButton: some View {
		Button {
			player?.skipToBeginning()
		} label: {
			Image(systemName: "arrow.counterclockwise.circle")
				.font(.system(size: .eight * 4))
		}
		.disabled(whenNil: tapeDeckDisplay.status)
	}
	private var skipBackButton: some View {
		Button {
			player?.currentPlaybackTime -= 15
		} label: {
			Image(systemName: "gobackward.15")
				.font(.system(size: .eight * 4))
		}
		.disabled(whenNil: tapeDeckDisplay.status)
	}
	
	private var playPauseButton: some View {
		Button {
			guard let status = tapeDeckDisplay.status else { return }
			if status.isInPlayMode {
				player?.pause()
			} else {
				player?.play()
			}
		} label: {
			if
				let status = tapeDeckDisplay.status,
				status.isInPlayMode
			{
				Image(systemName: "pause.circle")
					.font(.system(size: .eight * 6))
			} else {
				Image(systemName: "play.circle")
					.font(.system(size: .eight * 6))
			}
		}
		.disabled(whenNil: tapeDeckDisplay.status)
	}
	
	private var skipForwardButton: some View {
		Button {
			player?.currentPlaybackTime += 15
		} label: {
			Image(systemName: "goforward.15")
				.font(.system(size: .eight * 4))
		}
		.disabled(whenNil: tapeDeckDisplay.status)
	}
	private var nextButton: some View {
		Button {
			player?.skipToNextItem()
		} label: {
			Image(systemName: "arrow.forward.circle")
				.font(.system(size: .eight * 4))
		}
		.disabled(whenNil: tapeDeckDisplay.status)
	}
}
