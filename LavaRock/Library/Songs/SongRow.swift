//
//  SongRow.swift
//  LavaRock
//
//  Created by h on 2022-12-11.
//

import SwiftUI

struct SongRow: View {
	let trackDisplay: String
	let song_title: String?
	let artist_if_different_from_album_artist: String?
	let songID: SongID
	
	@ObservedObject private var tapeDeckStatus: TapeDeckStatus = .shared
	var body: some View {
		
		HStack {
			HStack(
				alignment: .firstTextBaseline,
				spacing: .eight * (1 + 1/2) // 12
			) {
				Text(trackDisplay)
					.monospacedDigit()
					.foregroundColor(.secondary)
				
				VStack(
					alignment: .leading,
					spacing: .eight * 1/2 // 4
				) {
					Text(song_title ?? SongMetadatumPlaceholder.unknownTitle)
					
					if let artist = artist_if_different_from_album_artist {
						Text(artist)
							.font(.caption)
							.foregroundColor(.secondary)
							.padding(.bottom, .eight * 1/4) // 2
					}
				}
				.alignmentGuide(.listRowSeparatorLeading) { textStackDimensions in
					textStackDimensions[.leading]
				}
			}
			
			Spacer()
			
			AvatarImage(
				songID: songID
			)
			
			// TO DO: Expand tappable area
			Button {
			} label: {
				Image(systemName: "ellipsis")
					.font(.body)
					.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
					.foregroundColor(.primary)
			}
			.alignmentGuide(.listRowSeparatorTrailing) { moreButtonDimensions in
				// TO DO: This indents the trailing inset in editing mode. Should we do that?
				moreButtonDimensions[.trailing]
			}
		}
		.padding(.top, .eight * -1/4) // -2
		
		.accessibilityElement()
		.accessibilityLabel({ () -> String in
			let nowPlayingStatusAccessibilityLabel: String? = {
				guard
					let status = tapeDeckStatus.current,
					songID == status.currentSongID
				else {
					return nil
				}
				if status.isPlaying {
					return LRString.nowPlaying
				} else {
					return LRString.paused
				}
			}()
			
			return [
				nowPlayingStatusAccessibilityLabel,
				trackDisplay,
				song_title,
				artist_if_different_from_album_artist,
			].compactedAndFormattedAsNarrowList()
		}())
		
		.accessibilityAddTraits(.isButton)
		
		.accessibilityInputLabels(
			[
				song_title, // Excludes the “unknown title” placeholder, which is currently a dash.
			].compacted()
		)
		
	}
}
