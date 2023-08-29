//
//  Avatar.swift
//  LavaRock
//
//  Created by h on 2022-12-12.
//

import SwiftUI

enum Avatar {
	static let pausedSFSymbolName = "speaker.fill"
	static let playingSFSymbolName = "speaker.wave.2.fill"
}

enum AvatarStatus {
	case notPlaying
	case paused
	case playing
	
	var uiImage__: UIImage? {
		switch self {
			case .notPlaying:
				return nil
			case .paused:
				return UIImage(systemName: Avatar.pausedSFSymbolName)
			case .playing:
				return UIImage(systemName: Avatar.playingSFSymbolName)
		}
	}
	
	var axLabel: String? {
		switch self {
			case .notPlaying:
				return nil
			case .paused:
				return LRString.paused
			case .playing:
				return LRString.nowPlaying
		}
	}
}

@MainActor
protocol AvatarDisplaying__: AnyObject {
	// Adopting types must…
	// • Call `indicateAvatarStatus__` whenever appropriate.
	
	func indicateAvatarStatus__(_ avatarStatus: AvatarStatus)
}
extension FolderCell: AvatarDisplaying__ {
	func indicateAvatarStatus__(_ avatarStatus: AvatarStatus) {
		if Self.usesSwiftUI__ { return }
		
		spacerSpeakerImageView.maximumContentSizeCategory = .extraExtraExtraLarge
		speakerImageView.maximumContentSizeCategory = spacerSpeakerImageView.maximumContentSizeCategory
		
		spacerSpeakerImageView.image = UIImage(systemName: Avatar.playingSFSymbolName)
		speakerImageView.image = avatarStatus.uiImage__
		
		accessibilityLabel = [
			avatarStatus.axLabel,
			rowContentAccessibilityLabel__,
		].compactedAndFormattedAsNarrowList()
	}
}
extension SongCell: AvatarDisplaying__ {
	func indicateAvatarStatus__(_ avatarStatus: AvatarStatus) {
		if Self.usesSwiftUI__ { return }
		
		spacerSpeakerImageView.maximumContentSizeCategory = .extraExtraExtraLarge
		speakerImageView.maximumContentSizeCategory = spacerSpeakerImageView.maximumContentSizeCategory
		
		spacerSpeakerImageView.image = UIImage(systemName: Avatar.playingSFSymbolName)
		speakerImageView.image = avatarStatus.uiImage__
		
		accessibilityLabel = [
			avatarStatus.axLabel,
			rowContentAccessibilityLabel__,
		].compactedAndFormattedAsNarrowList()
	}
}

struct AvatarImage: View {
	let libraryItem: LibraryItem
	
	@ObservedObject private var tapeDeckStatus: TapeDeckStatus = .shared
	@ObservedObject private var musicLibrary: MusicLibrary = .shared // In case the user added or deleted the current song. Currently, the view body never actually references this.
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
		Image(systemName: Avatar.playingSFSymbolName)
			.fontBody_dynamicTypeSizeUpToXxxLarge()
			.imageScale(.small)
	}
	@ViewBuilder
	private var foregroundView: some View {
		switch status {
			case .notPlaying:
				EmptyView()
			case .paused:
				Image(systemName: Avatar.pausedSFSymbolName)
					.foregroundStyle(Color.accentColor)
					.fontBody_dynamicTypeSizeUpToXxxLarge()
					.imageScale(.small)
			case .playing:
				playing_image
					.foregroundStyle(Color.accentColor)
		}
	}
}
