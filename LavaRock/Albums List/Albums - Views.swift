//
//  Albums - Views.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit
import SwiftUI
import OSLog

enum AlbumRowMode {
	case normal
	case modal // disabled
	case modalTinted // disabledTinted
}
struct AlbumHeader: View {
	let album: Album
	let maxHeight: CGFloat
	let mode: AlbumRowMode
	
	var body: some View {
		VStack(spacing: 0) {
			CoverArtView(
				albumRepresentative: album.representativeSongInfo(), // TO DO: Redraw when artwork changes
				largerThanOrEqualToSizeInPoints: maxHeight)
			.frame(
				maxWidth: .infinity, // Horizontally centers narrow artwork
				maxHeight: maxHeight)
			.offset(y: -0.5)
			
			Divider()
				.offset(y: -1)
			
			AlbumInfoRow(album: album)
				.padding(.top, .eight * 5/4)
				.padding(.horizontal)
				.padding(
					.bottom,
					Enabling.bigAlbums ? (.eight * 5/2) : nil
				)
		}
		.alignmentGuide_separatorLeading()
		.alignmentGuide_separatorTrailing()
		.opacity({ () -> Double in
			switch mode {
				case .normal:
					return 1
				case .modal:
					return .oneFourth // Close to what Files pickers use
				case .modalTinted:
					return .oneHalf
			}
		}())
		.background {
			if case AlbumRowMode.modalTinted = mode {
				Color.accentColor.opacity(.oneEighth)
			}
		}
		// TO DO: Accessibility traits
	}
}
struct CoverArtView: View {
	let albumRepresentative: (any SongInfo)?
	let largerThanOrEqualToSizeInPoints: CGFloat
	
	var body: some View {
		let uiImageOptional = albumRepresentative?.coverArt(atLeastInPoints: CGSize(
			width: largerThanOrEqualToSizeInPoints,
			height: largerThanOrEqualToSizeInPoints))
		if let uiImage = uiImageOptional {
			Image(uiImage: uiImage)
				.resizable() // Lets 1 image point differ from 1 screen point
				.scaledToFit() // Maintains aspect ratio
				.accessibilityLabel(LRString.albumArtwork)
				.accessibilityIgnoresInvertColors()
		} else {
			ZStack {
				Color(uiColor: .secondarySystemBackground) // Close to what Apple Music uses
					.aspectRatio(1, contentMode: .fit)
				Image(systemName: "music.note")
					.foregroundStyle(.secondary)
					.font(.system(size: .eight * 4))
			}
			.accessibilityLabel(LRString.albumArtwork)
			.accessibilityIgnoresInvertColors()
		}
	}
}
struct AlbumInfoRow: View {
	let album: Album
	
	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			VStack(
				alignment: .leading,
				spacing: .eight * 3/4
			) {
				Text(album.titleFormatted()) // “Rubber Soul”
					.font_title2_bold()
				
				if let releaseDate = album.releaseDateEstimateFormattedOptional() {
					let segment: String = " \(LRString.interpunct) \(releaseDate)" // “ · Dec 3, 1965”
					(
						Text(album.albumArtistFormatted()) // “The Beatles”
							.bold()
						+
						Text(segment)
					)
					.foregroundStyle(.secondary)
					.font(.caption2)
				} else {
					Text(album.albumArtistFormatted())
						.foregroundStyle(.secondary)
						.font_caption2_bold()
				}
			}
			Spacer()
			if Enabling.bigAlbums {
				AvatarImage(libraryItem: album)
				Chevron()
			}
		}
	}
}

// TO DO: Delete
final class AlbumCell: UITableViewCell {
	@IBOutlet var spacerSpeakerImageView: UIImageView!
	@IBOutlet var speakerImageView: UIImageView!
	
	@IBOutlet private var mainStack: UIStackView!
	@IBOutlet private var coverArtView: UIImageView!
	@IBOutlet private var textStack: UIStackView!
	@IBOutlet private var titleLabel: UILabel!
	@IBOutlet private var releaseDateLabel: UILabel!
}
