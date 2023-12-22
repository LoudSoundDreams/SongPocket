//
//  Avatar.swift
//  LavaRock
//
//  Created by h on 2022-12-12.
//

import SwiftUI
import MusicKit

enum AvatarStatus {
	case notPlaying
	case paused
	case playing
	
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

struct AvatarImage: View {
	let libraryItem: LibraryItem
	
	@ObservedObject var state: MusicPlayer.State
	@ObservedObject var queue: MusicPlayer.Queue
	@ObservedObject private var musicLibrary: MusicLibrary = .shared // In case the user added or deleted the current song. Currently, even if the view body never actually mentions this, merely including this property refreshes the view at the right times.
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
			playing_image.hidden()
			foregroundView
		}
		.accessibilityElement()
		.accessibilityLabel(status.axLabel ?? "")
	}
	
	private var playing_image: some View {
		Image(systemName: "speaker.wave.2.fill")
			.fontBody_dynamicTypeSizeUpToXxxLarge()
			.imageScale(.small)
	}
	@ViewBuilder
	private var foregroundView: some View {
		switch status {
			case .notPlaying:
				EmptyView()
			case .paused:
				Image(systemName: "speaker.fill")
					.foregroundStyle(Color.accentColor)
					.fontBody_dynamicTypeSizeUpToXxxLarge()
					.imageScale(.small)
			case .playing:
				playing_image
					.foregroundStyle(Color.accentColor)
		}
	}
}

@MainActor
protocol AvatarReflecting: AnyObject {
	func reflectAvatarStatus(_ status: AvatarStatus)
}
extension CollectionCell: AvatarReflecting {
	func reflectAvatarStatus(_ status: AvatarStatus) {
		if Self.usesSwiftUI { return }
		
		spacerSpeakerImageView.maximumContentSizeCategory = .extraExtraExtraLarge
		speakerImageView.maximumContentSizeCategory = spacerSpeakerImageView.maximumContentSizeCategory
		
		spacerSpeakerImageView.image = AvatarStatus.playing.uiImage
		speakerImageView.image = status.uiImage
		
		accessibilityLabel = [status.axLabel, rowContentAccessibilityLabel__].compactedAndFormattedAsNarrowList()
	}
}
extension SongCell: AvatarReflecting {
	func reflectAvatarStatus(_ status: AvatarStatus) {
		if Self.usesSwiftUI { return }
		
		spacerSpeakerImageView.maximumContentSizeCategory = .extraExtraExtraLarge
		speakerImageView.maximumContentSizeCategory = spacerSpeakerImageView.maximumContentSizeCategory
		
		spacerSpeakerImageView.image = AvatarStatus.playing.uiImage
		speakerImageView.image = status.uiImage
		
		accessibilityLabel = [status.axLabel, rowContentAccessibilityLabel__].compactedAndFormattedAsNarrowList()
	}
}
