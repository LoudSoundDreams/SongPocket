//
//  AlbumInfoRow.swift
//  LavaRock
//
//  Created by h on 2022-12-03.
//

import SwiftUI

struct AlbumInfoRow: View {
	let albumTitle: String
	let album: Album
	
	var body: some View {
		VStack(
			spacing: .eight // 8
		) {
			Text(albumTitle)
				.multilineTextAlignment(.center)
				.font(.title2)
				.fontWeight(.bold)
			
			Text({ () -> String in
				let albumArtistSegment: String
				= album.representativeAlbumArtistFormattedOptional()
				?? Album.unknownAlbumArtistPlaceholder
				
				let releaseDateSegment: String = {
					guard let releaseDateString = album.releaseDateEstimateFormattedOptional() else {
						return ""
					}
					return " " + LRString.interpunct + " " + releaseDateString
				}()
				
				return albumArtistSegment + releaseDateSegment
			}())
			.multilineTextAlignment(.center)
			.font(.caption)
			.fontWeight(.bold)
			.foregroundColor(.secondary)
		}
		.padding(.top, .eight * -1/4) // -2
		.padding(.bottom, .eight * 3/8) // 3
		.frame(maxWidth: .infinity)
		.alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
			viewDimensions[.leading]
		}
		.alignmentGuide(.listRowSeparatorTrailing) { viewDimensions in
			viewDimensions[.trailing]
		}
	}
}
