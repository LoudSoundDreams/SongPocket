// 2022-12-12

import SwiftUI
import MusicKit

enum AvatarStatus {
	case notPlaying, paused, playing
	
	var uiImage: UIImage? {
		switch self {
			case .notPlaying: return nil
			case .paused: return UIImage(systemName: "speaker.fill")
			case .playing: return UIImage(systemName: "speaker.wave.2.fill")
		}
	}
	
	var axLabel: String? {
		switch self {
			case .notPlaying: return nil
			case .paused: return LRString.paused
			case .playing: return LRString.nowPlaying
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
struct AvatarImage: View {
	let libraryItem: LibraryItem
	@ObservedObject var state: MusicPlayer.State
	@ObservedObject var queue: MusicPlayer.Queue
	
	@ObservedObject private var musicRepo: MusicRepo = .shared // In case the user added or deleted the current song. Currently, even if the view body never actually mentions this, merely including this property refreshes the view at the right times.
	private var status: AvatarStatus {
		if !libraryItem.containsPlayhead() {
			return .notPlaying
		}
#if targetEnvironment(simulator)
		return .playing
#else
		if state.playbackStatus == .playing {
			return .playing
		} else {
			return .paused
		}
#endif
	}
	
	var body: some View {
		ZStack(alignment: .leading) {
			AvatarPlayingImage().hidden()
			foregroundView
		}
		.accessibilityElement()
		.accessibilityLabel(status.axLabel ?? "")
	}
	@ViewBuilder private var foregroundView: some View {
		switch status {
			case .notPlaying:
				EmptyView()
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
