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
			VStack(alignment: .leading, spacing: .eight * 5/8) {
				Text(album.titleFormatted()) // “Rubber Soul”
					.font_title2_bold()
				Text(album.albumArtistFormatted()) // “The Beatles”
					.foregroundStyle(.secondary)
					.font_caption2_bold()
				if let releaseDate = album.releaseDateEstimateFormattedOptional() {
					Text(releaseDate) // “Dec 3, 1965”
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
final class AlbumCell: UITableViewCell {
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
		
		coverArtView.accessibilityIgnoresInvertColors = true
		// Round artwork corners
		let artViewLayer = coverArtView.layer
		artViewLayer.cornerCurve = .continuous
		artViewLayer.cornerRadius = .eight * 1/2
		
		orientMainStack()
		
		accessoryView = {
			let chevron_uiView = UIHostingController(rootView: Chevron()).view
			chevron_uiView?.sizeToFit()
			chevron_uiView?.backgroundColor = nil
			return chevron_uiView
		}()
	}
	
	func configure(
		with album: Album,
		mode: AlbumRowMode
	) {
		let representative = album.representativeSongInfo() // Can be `nil`
		
		let widthAndHeightInPoints = coverArtView.bounds.width
		coverArtView.image = representative?.coverArt(atLeastInPoints: CGSize(
			width: widthAndHeightInPoints,
			height: widthAndHeightInPoints))
		
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
