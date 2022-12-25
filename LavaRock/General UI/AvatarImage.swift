//
//  AvatarImage.swift
//  LavaRock
//
//  Created by h on 2022-12-12.
//

import SwiftUI

struct AvatarImage: View {
	let songID: SongID
	
	@ObservedObject private var tapeDeckStatus: TapeDeckStatus = .shared
	
	private enum State {
		case notPlaying
		case paused
		case playing
	}
	
	private var state: State {
		guard
			let status = tapeDeckStatus.current,
			songID == status.now_playing_SongID
		else {
			return .notPlaying
		}
		if status.isPlaying {
			return .playing
		} else {
			return .paused
		}
	}
	
	var body: some View {
		ZStack {
			
			Image(systemName: Avatar.preference.playingSFSymbolName)
				.fontBody_imageScaleSmall_dynamicTypeSizeUpToXxxLarge()
				.hidden()
			
			switch state {
			case .notPlaying:
				EmptyView()
			case .paused:
				Image(systemName: Avatar.preference.pausedSFSymbolName)
					.fontBody_imageScaleSmall_dynamicTypeSizeUpToXxxLarge()
					.foregroundColor(.accentColor)
			case .playing:
				Image(systemName: Avatar.preference.playingSFSymbolName)
					.fontBody_imageScaleSmall_dynamicTypeSizeUpToXxxLarge()
					.foregroundColor(.accentColor)
			}
			
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
