//
//  Songs List.swift
//  LavaRock
//
//  Created by h on 2023-09-01.
//

import SwiftUI

struct AlbumHeader: View {
	let album: Album
	let trackNumberSpacer: String
	
	var body: some View {
		HStack(spacing: .eight * 5/4) {
			Text(trackNumberSpacer)
				.monospacedDigit()
				.hidden()
				.alignmentGuide_separatorLeading()
			
			VStack(
				alignment: .leading,
				spacing: .eight * 1/2
			) {
				Text(album.albumArtistFormatted()) // “The Beatles”
					.foregroundStyle(.secondary)
					.fontCaption2_bold()
				Text(album.titleFormatted()) // “Rubber Soul”
					.fontTitle2_bold()
			}
			
			Spacer()
		}
		.alignmentGuide_separatorTrailing()
	}
}

struct SongRow: View {
	let song: Song
	let trackDisplay: String
	let artist_if_different_from_album_artist: String?
	
	@ObservedObject private var tapeDeckStatus: TapeDeckStatus = .shared
	var body: some View {
		
		HStack {
			HStack(
				alignment: .firstTextBaseline,
				spacing: .eight * (1 + 1/2) // 12
			) {
				Text(trackDisplay)
					.foregroundStyle(.secondary)
					.monospacedDigit()
				
				VStack(
					alignment: .leading,
					spacing: .eight * 1/2 // 4
				) {
					Text(song.songInfo()?.titleOnDisk ?? SongInfoPlaceholder.unknownTitle)
					if let artist = artist_if_different_from_album_artist {
						Text(artist)
							.foregroundStyle(.secondary)
							.fontFootnote()
							.padding(.bottom, .eight * 1/4) // 2
					}
				}
				.alignmentGuide_separatorLeading()
			}
			
			Spacer()
			
			AvatarImage(libraryItem: song).accessibilitySortPriority(10)
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
		.accessibilityInputLabels([song.songInfo()?.titleOnDisk].compacted())
		
	}
}
