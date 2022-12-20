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
	
	var body: some View {
		ZStack {
			
			Image(systemName: Avatar.preference.playingSFSymbolName)
				.fontBody_imageScaleSmall_dynamicTypeSizeUpToXxxLarge()
				.hidden()
			
			if
				let status = tapeDeckStatus.current,
				songID == status.now_playing_SongID
			{
				if status.isPlaying {
					Image(systemName: Avatar.preference.playingSFSymbolName)
						.fontBody_imageScaleSmall_dynamicTypeSizeUpToXxxLarge()
						.foregroundColor(.accentColor)
				} else {
					Image(systemName: Avatar.preference.pausedSFSymbolName)
						.fontBody_imageScaleSmall_dynamicTypeSizeUpToXxxLarge()
						.foregroundColor(.accentColor)
				}
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
