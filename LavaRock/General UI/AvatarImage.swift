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
			
			Image(systemName: "tortoise")
				.fontBodyDynamicTypeSizeUpToXxxLarge()
				.hidden()
			
			if
				let status = tapeDeckStatus.current,
				songID == status.now_playing_SongID
			{
				if status.isPlaying {
					Image(systemName: "tortoise.fill")
						.fontBodyDynamicTypeSizeUpToXxxLarge()
						.foregroundColor(.accentColor)
				} else {
					Image(systemName: "tortoise")
						.fontBodyDynamicTypeSizeUpToXxxLarge()
						.foregroundColor(.accentColor)
				}
			}
			
		}
	}
}

private extension View {
	func fontBodyDynamicTypeSizeUpToXxxLarge() -> some View {
		return self
			.font(.body)
			.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
	}
}
