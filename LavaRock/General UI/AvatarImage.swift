//
//  AvatarImage.swift
//  LavaRock
//
//  Created by h on 2022-12-12.
//

import SwiftUI

enum AvatarStatus {
	case notPlaying
	case paused
	case playing
	
	var uiImage: UIImage? {
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
		ZStack(
			alignment: .leading
		) {
			// Spacer
			playing_image
				.hidden()
			
			// Foreground
			foregroundView // If SwiftUI detects that this is an `EmptyView`, it doesn’t bother with the following accessibility label.
		}
	}
	
	private var playing_image: some View {
		Image(systemName: Avatar.preference.playingSFSymbolName)
			.fontBody_imageScaleSmall_dynamicTypeSizeUpToXxxLarge()
	}
	
	@ViewBuilder
	private var foregroundView: some View {
		switch status {
		case .notPlaying:
			Image(systemName: "aoeu")
//			EmptyView()
		case .paused:
			Image(systemName: Avatar.preference.pausedSFSymbolName)
				.fontBody_imageScaleSmall_dynamicTypeSizeUpToXxxLarge()
				.foregroundColor(.accentColor)
		case .playing:
			playing_image
				.foregroundColor(.accentColor)
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
