//
//  AvatarImage.swift
//  LavaRock
//
//  Created by h on 2022-12-12.
//

import SwiftUI

enum AvatarState {
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
	
	var accessibilityLabel: String? {
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
	let state: AvatarState
	
	var body: some View {
		ZStack(
			alignment: .leading
		) {
			// Spacer
			playing_image
				.hidden()
			
			// Foreground
			switch state {
			case .notPlaying:
				EmptyView()
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
	
	private var playing_image: some View {
		Image(systemName: Avatar.preference.playingSFSymbolName)
			.fontBody_imageScaleSmall_dynamicTypeSizeUpToXxxLarge()
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
