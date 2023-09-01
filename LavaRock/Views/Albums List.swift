//
//  Albums List.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import SwiftUI
import OSLog

struct AlbumCard: View {
	enum Mode {
		case normal
		case disabled
		case disabledTinted
	}
	
	let album: Album
	let maxHeight: CGFloat
	let mode: Mode
	
	@Environment(\.pixelLength) private var pointsPerPixel
	private static let borderWidthInPixels: CGFloat = 2
	var body: some View {
		VStack(spacing: 0) {
			Rectangle().frame(height: 1/2 * Self.borderWidthInPixels * pointsPerPixel).hidden()
			CoverArtView(
				albumRepresentative: album.representativeSongInfo(), // TO DO: Redraw when artwork changes
				largerThanOrEqualToSizeInPoints: maxHeight)
			.background(
				Rectangle()
					.stroke(
						Color(uiColor: .separator), // As of iOS 16.6, only this is correct in dark mode, not `opaqueSeparator`.
						lineWidth: {
							// Add a grey border exactly 1 pixel wide, like list separators.
							// Draw outside the artwork; don’t overlap it.
							// The artwork itself will obscure half the stroke width.
							// SwiftUI interprets our return value in points, not pixels.
							return Self.borderWidthInPixels * pointsPerPixel
						}()
					)
			)
			.frame(
				maxWidth: .infinity, // Horizontally centers narrow artwork
				maxHeight: maxHeight)
			.accessibilityLabel(album.titleFormatted())
			.accessibilitySortPriority(10)
			
			AlbumInfoRow(album: album)
				.padding(.top, .eight * 3/2)
				.padding(.horizontal)
				.padding(.bottom, .eight * 4)
				.accessibilityRespondsToUserInteraction(false)
		}
		.alignmentGuide_separatorLeading()
		.alignmentGuide_separatorTrailing()
		.opacity({ () -> Double in
			switch mode {
				case .normal:
					return 1
				case .disabled:
					return .oneFourth // Close to what Files pickers use
				case .disabledTinted:
					return .oneHalf
			}
		}())
		.background {
			if mode == .disabledTinted {
				Color.accentColor.opacity(.oneEighth)
			}
		}
		.accessibilityAddTraits(.isButton)
		.accessibilityInputLabels([album.titleFormatted()])
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
			ZStack(alignment: .leading) {
				Text("1999").hidden() // Preserves vertical height
				if let releaseDate = album.releaseDateEstimateFormattedOptional() {
					Text(releaseDate)
				}
			}
			.foregroundStyle(.secondary)
			.fontFootnote()
			Spacer()
			AvatarImage(libraryItem: album).accessibilitySortPriority(10) // Bigger is sooner
			Chevron()
		}
		.accessibilityElement(children: .combine)
	}
}
