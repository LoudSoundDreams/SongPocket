//
//  AlbumInfoRow.swift
//  LavaRock
//
//  Created by h on 2022-12-03.
//

import SwiftUI

struct AlbumInfoRow: View {
	let albumTitle: String
	let albumArtist: String
	let releaseDateString: String?
	
	init(
		albumTitle: String,
		albumArtist: String?, // `nil` uses placeholder
		releaseDateString: String? // `nil` omits field
	) {
		self.albumTitle = albumTitle
		self.albumArtist = albumArtist ?? Album.unknownAlbumArtistPlaceholder
		self.releaseDateString = releaseDateString
	}
	
	var body: some View {
		VStack(
			spacing: .eight // 8
		) {
			// “Please Please Me”
			Text(albumTitle)
				.multilineTextAlignment(.center)
				.font(.title2)
				.fontWeight(.bold)
			
			// Subtitle
			Group {
				// Concatenate instances of `Text`
				
				// “The Beatles”
				Text(albumArtist)
				.fontWeight(.bold) // As of iOS 16.2 developer beta 4, this is thicker than `.bold()`, peculiarly
				+
				
				// “· Mar 22, 1963”
				Text({ () -> String in
					guard let releaseDateString else {
						return ""
					}
					return " " + LRString.interpunct + " " + releaseDateString
				}())
			}
			.multilineTextAlignment(.center)
			.font(.caption)
			.foregroundColor(.secondary)
		}
		.padding(.top, .eight * -1/4) // -2
		.padding(.bottom, .eight * 3/8) // 3
		.frame(maxWidth: .infinity)
	}
}
