//
//  Avatar - Views.swift
//  LavaRock
//
//  Created by h on 2022-12-12.
//

import SwiftUI

// MARK: - Status

enum AvatarStatus {
	case notPlaying
	case paused
	case playing
	
	var uiImage__: UIImage? {
		switch self {
			case .notPlaying:
				return nil
			case .paused:
				return UIImage(systemName: Avatar.preference.pausedSFSymbolName)
			case .playing:
				return UIImage(systemName: Avatar.preference.playingSFSymbolName)
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
		
		spacerSpeakerImageView.image = UIImage(systemName: Avatar.preference.playingSFSymbolName)
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
		
		spacerSpeakerImageView.image = UIImage(systemName: Avatar.preference.playingSFSymbolName)
		speakerImageView.image = avatarStatus.uiImage__
		
		accessibilityLabel = [
			avatarStatus.axLabel,
			rowContentAccessibilityLabel__,
		].compactedAndFormattedAsNarrowList()
	}
}

// MARK: - Image

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
	
	@ObservedObject private var current: CurrentAvatar = .shared
	private var playing_image: some View {
		Image(systemName: current.avatar.playingSFSymbolName)
			.fontBody_dynamicTypeSizeUpToXxxLarge()
			.imageScale(.small)
	}
	@ViewBuilder
	private var foregroundView: some View {
		switch status {
			case .notPlaying:
				EmptyView()
			case .paused:
				Image(systemName: current.avatar.pausedSFSymbolName)
					.foregroundStyle(Color.accentColor)
					.fontBody_dynamicTypeSizeUpToXxxLarge()
					.imageScale(.small)
			case .playing:
				playing_image
					.foregroundStyle(Color.accentColor)
		}
	}
}
