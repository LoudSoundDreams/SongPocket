//
//  SongRow.swift
//  LavaRock
//
//  Created by h on 2023-09-01.
//

import SwiftUI

struct SongRow: View {
	let song: Song
	let trackDisplay: String
	let song_title: String?
	let artist_if_different_from_album_artist: String?
	
	@ObservedObject private var tapeDeckStatus: TapeDeckStatus = .shared
	var body: some View {
		
		HStack {
			HStack(
				alignment: .firstTextBaseline,
				spacing: .eight * (1 + 1/2) // 12
			) {
				Text(trackDisplay)
					.monospacedDigit()
					.foregroundStyle(.secondary)
				
				VStack(
					alignment: .leading,
					spacing: .eight * 1/2 // 4
				) {
					Text(song_title ?? SongInfoPlaceholder.unknownTitle)
					if let artist = artist_if_different_from_album_artist {
						Text(artist)
							.fontFootnote()
							.foregroundStyle(.secondary)
							.padding(.bottom, .eight * 1/4) // 2
					}
				}
				.alignmentGuide_separatorLeading()
			}
			
			Spacer()
			
			AvatarImage(libraryItem: song)
				.accessibilitySortPriority(10)
			
			Button {
			} label: {
				Image(systemName: "ellipsis")
					.foregroundStyle(.primary)
					.fontBody_dynamicTypeSizeUpToXxxLarge()
			}
		}
		.padding(.top, .eight * -1/4) // -2
		.accessibilityElement(children: .combine)
		.accessibilityAddTraits(.isButton)
		.accessibilityInputLabels([song_title].compacted())
		
	}
}
