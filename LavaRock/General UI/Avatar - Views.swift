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
		if tapeDeckStatus.isPlaying {
			return .playing
		} else {
			return .paused
		}
	}
	
	var body: some View {
		ZStack(alignment: .leading) {
			// Spacer
			playing_image
				.hidden()
			
			// Foreground
			foregroundView
				.accessibilityElement()
				.accessibilityLabel(status.axLabel ?? "")
		}
	}
	
	@ObservedObject private var current: CurrentAvatar = .shared
	private var playing_image: some View {
		Image(systemName: current.avatar.playingSFSymbolName)
			.fontBody_imageScaleSmall_dynamicTypeSizeUpToXxxLarge()
	}
	@ViewBuilder
	private var foregroundView: some View {
		switch status {
			case .notPlaying:
				// If SwiftUI detects that this is an `EmptyView`, it doesn’t bother with the `accessibilityElement` modifier.
				Image(systemName: "")
//				EmptyView()
			case .paused:
				Image(systemName: current.avatar.pausedSFSymbolName)
					.fontBody_imageScaleSmall_dynamicTypeSizeUpToXxxLarge()
					.foregroundStyle(Color.accentColor)
			case .playing:
				playing_image
					.foregroundStyle(Color.accentColor)
		}
	}
}
private extension View {
	func fontBody_imageScaleSmall_dynamicTypeSizeUpToXxxLarge() -> some View {
		return self
			.font(.body)
			.imageScale(.small)
			.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
	}
}
