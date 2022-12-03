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
			spacing: .eight
		) {
			Text(albumTitle)
				.multilineTextAlignment(.center)
				.font(.title2)
				.fontWeight(.bold)
			
			Text({ () -> String in
				let albumArtistString: String
				= album.representativeAlbumArtistFormattedOptional()
				?? Album.unknownAlbumArtistPlaceholder
				
				let releaseDateString: String = {
					guard let releaseDateString = album.releaseDateEstimateFormattedOptional() else {
						return ""
					}
					return " " + LRString.interpunct + " " + releaseDateString
				}()
				
				return albumArtistString + releaseDateString
			}())
			.multilineTextAlignment(.center)
			.font(.caption)
			.fontWeight(.bold)
			.foregroundColor(.secondary)
		}
		.padding(.bottom, .eight * 1/2)
		.frame(maxWidth: .infinity)
		.alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
			viewDimensions[.leading]
		}
		.alignmentGuide(.listRowSeparatorTrailing) { viewDimensions in
			viewDimensions[.trailing]
		}
	}
}
