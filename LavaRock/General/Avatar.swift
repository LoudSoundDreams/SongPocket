//
//  Avatar.swift
//  LavaRock
//
//  Created by h on 2022-12-12.
//

import SwiftUI

enum AvatarStatus {
	case notPlaying
	case paused
	case playing
	
	var uiImage__: UIImage? {
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

@MainActor
protocol AvatarReflecting__: AnyObject {
	func reflectStatus__(_ status: AvatarStatus)
}
extension CollectionCell: AvatarReflecting__ {
	func reflectStatus__(_ status: AvatarStatus) {
		if Self.usesSwiftUI__ { return }
		
		spacerSpeakerImageView.maximumContentSizeCategory = .extraExtraExtraLarge
		speakerImageView.maximumContentSizeCategory = spacerSpeakerImageView.maximumContentSizeCategory
		
		spacerSpeakerImageView.image = AvatarStatus.playing.uiImage__
		speakerImageView.image = status.uiImage__
		
		accessibilityLabel = [status.axLabel, rowContentAccessibilityLabel__].compactedAndFormattedAsNarrowList()
	}
}
extension SongCell: AvatarReflecting__ {
	func reflectStatus__(_ status: AvatarStatus) {
		if Self.usesSwiftUI__ { return }
		
		spacerSpeakerImageView.maximumContentSizeCategory = .extraExtraExtraLarge
		speakerImageView.maximumContentSizeCategory = spacerSpeakerImageView.maximumContentSizeCategory
		
		spacerSpeakerImageView.image = AvatarStatus.playing.uiImage__
		speakerImageView.image = status.uiImage__
		
		accessibilityLabel = [status.axLabel, rowContentAccessibilityLabel__].compactedAndFormattedAsNarrowList()
	}
}

struct AvatarImage: View {
	let libraryItem: LibraryItem
	
	@ObservedObject private var tapeDeckStatus: TapeDeckStatus = .shared
	private var status: AvatarStatus {
		guard
			libraryItem.containsPlayhead(),
			let tapeDeckStatus = tapeDeckStatus.current
		else {
			return .notPlaying
		}
#if targetEnvironment(simulator)
		return .playing
#else
		if tapeDeckStatus.isPlaying {
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
