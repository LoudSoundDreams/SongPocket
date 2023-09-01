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
			TrackNumberLabel(text: trackNumberSpacer, spacerText: trackNumberSpacer)
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
	let trackNumberSpacer: String
	let artist_if_different_from_album_artist: String?
	
	@ObservedObject private var tapeDeckStatus: TapeDeckStatus = .shared
	var body: some View {
		
		HStack(alignment: .firstTextBaseline) {
			HStack(
				alignment: .firstTextBaseline,
				spacing: .eight * 5/4 // Between track number and title
			) {
				TrackNumberLabel(text: trackDisplay, spacerText: trackNumberSpacer)
				
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
					.foregroundStyle(Color.primary)
					.fontBody_dynamicTypeSizeUpToXxxLarge()
			}
		}
		.padding(.top, .eight * -1/4) // -2
		.accessibilityElement(children: .combine)
		.accessibilityAddTraits(.isButton)
		.accessibilityInputLabels([song.songInfo()?.titleOnDisk].compacted())
		
	}
}

struct TrackNumberLabel: View {
	let text: String
	let spacerText: String
	
	var body: some View {
		ZStack(alignment: .trailing) {
			Text(spacerText).hidden()
			Text(text).foregroundStyle(.secondary)
		}
		.monospacedDigit()
	}
}
