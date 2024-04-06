// 2022-12-12

import SwiftUI
import MusicKit

struct Chevron: View {
	var body: some View {
		// Similar to what Apple Music uses for search results
		Image(systemName: "chevron.forward")
			.foregroundStyle(.secondary)
			.fontBody_dynamicTypeSizeUpToXxxLarge()
			.imageScale(.small)
	}
}

struct AvatarImage: View {
	let libraryItem: LibraryItem
	@ObservedObject var state: MusicPlayer.State
	@ObservedObject var queue: MusicPlayer.Queue
	
	private var status: Status {
		guard libraryItem.containsPlayhead() else { return .notPlaying }
#if targetEnvironment(simulator)
		return .playing
#else
		return (state.playbackStatus == .playing) ? .playing : .paused
#endif
	}
	enum Status {
		case notPlaying, paused, playing
	}
	@ObservedObject private var musicRepo: MusicRepo = .shared // In case the user added or deleted the current song. Currently, even if the view body never actually mentions this, merely including this property refreshes the view at the right times.
	
	var body: some View {
		ZStack(alignment: .leading) {
			AvatarPlayingImage().hidden()
			foregroundView
		}
		.accessibilityElement()
		.accessibilityLabel({
			switch status {
				case .notPlaying: return ""
				case .paused: return LRString.paused
				case .playing: return LRString.nowPlaying
			}
		}())
	}
	@ViewBuilder private var foregroundView: some View {
		switch status {
			case .notPlaying: EmptyView()
			case .paused:
				Image(systemName: "speaker.fill")
					.foregroundStyle(Color.accentColor)
					.fontBody_dynamicTypeSizeUpToXxxLarge()
					.imageScale(.small)
			case .playing:
				AvatarPlayingImage()
					.foregroundStyle(Color.accentColor)
					.symbolRenderingMode(.hierarchical)
		}
	}
}
struct AvatarPlayingImage: View {
	var body: some View {
		Image(systemName: "speaker.wave.2.fill")
			.fontBody_dynamicTypeSizeUpToXxxLarge()
			.imageScale(.small)
	}
}
