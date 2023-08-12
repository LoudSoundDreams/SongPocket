//
//  Albums - Views.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit
import SwiftUI
import OSLog

// MARK: - Header

struct AlbumHeader: View {
	let album: Album
	let maxHeight: CGFloat
	
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
				spacing: .eight * 5/8
			) {
				// “Rubber Soul”
				Text(album.titleFormatted())
					.font_title2_bold()
				
				// “The Beatles”
				Text(album.albumArtistFormatted())
					.foregroundStyle(.secondary)
					.font_caption2_bold()
				
				if let releaseDate = album.releaseDateEstimateFormattedOptional() {
					// “Dec 3, 1965”
					Text(releaseDate)
						.foregroundStyle(.secondary)
						.font_footnote()
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

// MARK: - Row

enum AlbumRowMode {
	case normal
	case modal
	case modalTinted
}

struct AlbumRow: View {
	let album: Album
	let mode: AlbumRowMode
	
	@Environment(\.pixelLength) private var pointsPerPixel
	@Environment(\.dynamicTypeSize) private var textSize: DynamicTypeSize
	private var isVertical: Bool {
		textSize >= .accessibility1
	}
	var body: some View {
		HStack {
			let contentStackLayout: AnyLayout = {
				if isVertical {
					return AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
				}
				return AnyLayout(HStackLayout(alignment: .top, spacing: 0))
			}()
			contentStackLayout {
				let coverArtVerticalMargin: CGFloat = .eight * 5/8
				let coverArtMaxWidth: CGFloat = {
					let minRowHeight: CGFloat = 44 * 3
					return minRowHeight - 2 * coverArtVerticalMargin
				}()
				CoverArtView(
					albumRepresentative: album.representativeSongInfo(),
					largerThanOrEqualToSizeInPoints: coverArtMaxWidth)
				.frame(width: coverArtMaxWidth)
				.clipShape(
					RoundedRectangle(cornerRadius: .eight * 1/2, style: .continuous)
				)
				.background(
					RoundedRectangle(cornerRadius: .eight * 1/2, style: .continuous)
						.stroke(
							Color(uiColor: .separator), // As of iOS 16.6, only this is correct in dark mode, not `opaqueSeparator`.
							lineWidth: { () -> CGFloat in
								// Add a border exactly 1 pixel wide.
								// The cover art itself will obscure half our return value.
								// SwiftUI interprets our return value in points, not pixels.
								let resultInPixels = 2
								let result = CGFloat(resultInPixels) * pointsPerPixel
								print(result)
								return result
							}()
						)
				)
				.padding(.vertical, coverArtVerticalMargin)
				.padding(.trailing, coverArtVerticalMargin * 2)
				
				VStack(alignment: .leading, spacing: .eight * 1/2) {
					Text(album.titleFormatted())
						.alignmentGuide_separatorLeading()
					if let releaseDate = album.releaseDateEstimateFormattedOptional() {
						Text(releaseDate)
							.foregroundStyle(.secondary)
							.font_footnote()
					}
				}
				// TO DO: Always keep wider than a certain width. (88 is good)
				.padding(.top, coverArtVerticalMargin * 2 - 5) // !
				.padding(.bottom, .eight)
			}
			
			Spacer()
			
			AvatarImage(libraryItem: album)
				.offset(y: -0.5)
				.accessibilitySortPriority(10)
		}
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
		.accessibilityElement(children: .combine)
		.accessibilityAddTraits(.isButton)
		.accessibilityInputLabels([album.titleFormatted()])
	}
}

final class AlbumCell: UITableViewCell {
	static let usesSwiftUI__ = 10 == 1
	
	@IBOutlet var spacerSpeakerImageView: UIImageView!
	@IBOutlet var speakerImageView: UIImageView!
	var rowContentAccessibilityLabel__: String? = nil
	
	@IBOutlet private var mainStack: UIStackView!
	@IBOutlet private var coverArtView: UIImageView!
	@IBOutlet private var textStack: UIStackView!
	@IBOutlet private var titleLabel: UILabel!
	@IBOutlet private var releaseDateLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		backgroundColor = .clear
		
		if !Self.usesSwiftUI__ {
			coverArtView.accessibilityIgnoresInvertColors = true
			// Round artwork corners
			let artViewLayer = coverArtView.layer
			artViewLayer.cornerCurve = .continuous
			artViewLayer.cornerRadius = .eight * 1/2
		}
		
		orientMainStack()
	}
	
	func configure(
		with album: Album,
		mode: AlbumRowMode
	) {
		if !Self.usesSwiftUI__ {
			let representative = album.representativeSongInfo() // Can be `nil`
			
			os_signpost(.begin, log: .albumsView, name: "Set cover art")
			let widthAndHeightInPoints = coverArtView.bounds.width
			coverArtView.image = representative?.coverArt(atLeastInPoints: CGSize(
				width: widthAndHeightInPoints,
				height: widthAndHeightInPoints))
			os_signpost(.end, log: .albumsView, name: "Set cover art")
			
			titleLabel.text = album.titleFormatted()
			releaseDateLabel.text = album.releaseDateEstimateFormattedOptional()
			
			if releaseDateLabel.text == nil {
				// We couldn’t determine the album’s release date.
				textStack.spacing = 0
			} else {
				textStack.spacing = .eight * 1/2
			}
			
			rowContentAccessibilityLabel__ = [
				titleLabel.text,
				releaseDateLabel.text,
			].compactedAndFormattedAsNarrowList()
			indicateAvatarStatus__(
				album.avatarStatus__()
			)
			
			accessibilityUserInputLabels = [album.titleFormatted()]
			
			switch mode {
				case .normal:
					contentView.layer.opacity = 1
				case .modal:
					contentView.layer.opacity = .oneFourth
				case .modalTinted:
					contentView.layer.opacity = .oneHalf
			}
		}
		
		switch mode {
			case .normal:
				accessibilityTraits.subtract(.notEnabled)
			case .modal:
				backgroundColor = .clear
				selectionStyle = .none
				accessibilityTraits.formUnion(.notEnabled)
			case .modalTinted:
				backgroundColor = .tintColor.withAlphaComponent(.oneEighth)
				selectionStyle = .none
				accessibilityTraits.formUnion(.notEnabled)
		}
	}
	
	// Xcode 15: Delete this and instead call `registerForTraitChanges` at some point.
	override func traitCollectionDidChange(
		_ previousTraitCollection: UITraitCollection?
	) {
		super.traitCollectionDidChange(previousTraitCollection)
		
		if
			previousTraitCollection?.preferredContentSizeCategory
				!= traitCollection.preferredContentSizeCategory
		{
			orientMainStack()
		}
	}
	
	private var textIsHuge: Bool {
		return traitCollection.preferredContentSizeCategory.isAccessibilityCategory
	}
	
	private static let mainStackSpacingWhenHorizontal: CGFloat = .eight * 10/8
	
	private func orientMainStack() {
		if textIsHuge {
			mainStack.axis = .vertical
			mainStack.alignment = .leading
			mainStack.spacing = UIStackView.spacingUseSystem
		} else {
			mainStack.axis = .horizontal
			mainStack.alignment = .center
			mainStack.spacing = Self.mainStackSpacingWhenHorizontal
		}
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.right = directionalLayoutMargins.trailing
		
		if Self.usesSwiftUI__ { return }
		
		// Draw artwork border
		// You must do this when switching between light and dark mode.
		let artViewLayer = coverArtView.layer
		// As of iOS 16.3…
		// • Apple Music uses a border and no shadow.
		// • Apple Books uses a shadow and no border.
		artViewLayer.borderColor = UIColor.separator.cgColor
		// Draw in pixels, not points
		let pixelsPerPoint = window?.screen.nativeScale ?? 2
		artViewLayer.borderWidth = 1 / pixelsPerPoint
		
		separatorInset.left = {
			var result: CGFloat = .zero
			result += contentView.frame.minX
			result += mainStack.frame.minX // 16
			if !textIsHuge {
				result += coverArtView.frame.width // 132
				result += mainStack.spacing
			}
			return result
		}()
	}
}
