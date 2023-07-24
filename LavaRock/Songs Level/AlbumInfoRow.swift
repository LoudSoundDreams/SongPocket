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
	let releaseDateStringOptional: String? // `nil` hides line
	
	var body: some View {
		HStack {
			VStack(
				alignment: .leading,
				spacing: .eight * 5/8
			) {
				// “Please Please Me”
				Text(albumTitle)
					.font(.title2)
					.bold()
				
				// “The Beatles”
				Text(albumArtist)
					.font(.footnote)
					.bold()
					.foregroundStyle(.secondary)
				
				if let releaseDate = releaseDateStringOptional {
					// “Mar 22, 1963”
					Text(releaseDate)
						.font(.caption)
						.foregroundStyle(.secondary)
				}
			}
			
			Spacer()
		}
		.padding(.bottom, .eight * 5/8)
	}
}
