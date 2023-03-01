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
		HStack {
			VStack(
				alignment: .leading,
				spacing: .eight * 5/8
			) {
				// “Please Please Me”
				Text(albumTitle)
					.font(.title2)
					.fontWeight(.bold)
				
				// “The Beatles”
				Text(albumArtist)
					.fontWeight(.bold) // As of iOS 16.2 developer beta 4, this is thicker than `.bold()`, peculiarly
					.font(.caption)
					.foregroundColor(.secondary)
				
				if let releaseDateString {
					// “Mar 22, 1963”
					Text(releaseDateString)
						.font(.caption)
						.foregroundColor(.secondary)
				}
			}
			
			Spacer()
		}
		.padding(.bottom, .eight * 4/8)
	}
}
