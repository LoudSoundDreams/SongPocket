//
//  CoverArtView.swift
//  LavaRock
//
//  Created by h on 2022-12-08.
//

import SwiftUI
import OSLog

struct CoverArtView: View {
	let albumRepresentative: (any SongInfo)?
	let maxHeight: CGFloat
	
	var body: some View {
		let uiImageOptional: UIImage? = {
			os_signpost(.begin, log: .songsView, name: "Draw cover art")
			defer {
				os_signpost(.end, log: .songsView, name: "Draw cover art")
			}
			return albumRepresentative?.coverArt(largerThanOrEqualToSizeInPoints: CGSize(
				width: maxHeight,
				height: maxHeight))
		}()
		if let uiImage = uiImageOptional {
			Image(uiImage: uiImage)
				.resizable()
				.scaledToFit()
				.frame(
					maxWidth: .infinity, // Horizontally centers narrow artwork
					maxHeight: maxHeight)
				.accessibilityLabel(LRString.albumArtwork)
				.accessibilityIgnoresInvertColors()
		} else {
			ZStack {
				Color(uiColor: .secondarySystemBackground) // Close to what Apple Music uses
					.aspectRatio(1, contentMode: .fit)
					.frame(
						maxWidth: .infinity,
						maxHeight: maxHeight)
				
				Image(systemName: "music.note")
					.foregroundStyle(.secondary)
					.font(.system(size: .eight * 4))
			}
			.accessibilityLabel(LRString.albumArtwork)
		}
	}
}
