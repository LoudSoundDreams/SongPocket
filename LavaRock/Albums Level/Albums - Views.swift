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
	case modal
	case modalTinted
}
struct AlbumRow: View {
	let album: Album
	let mode: AlbumRowMode
	
	static let verticalMargin: CGFloat = .eight * 5/8
	private static var coverArtMaxWidth: CGFloat {
		let minRowHeight: CGFloat = 44 * 3
		return minRowHeight - 2 * verticalMargin
	}
	@Environment(\.pixelLength) private var pixelLength
	var body: some View {
		HStack(spacing: Self.verticalMargin * 2) {
			CoverArtView(
				albumRepresentative: album.representativeSongInfo(),
				largerThanOrEqualToSizeInPoints: Self.coverArtMaxWidth)
			.frame(width: Self.coverArtMaxWidth)
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
							let pointsPerPixel = pixelLength
							let result = CGFloat(resultInPixels) * pointsPerPixel
							print(result)
							return result
						}()
					)
			)
			
			VStack(alignment: .leading, spacing: .eight * 1/2) {
				Text(album.titleFormatted())
					.alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
						viewDimensions[.leading]
					}
				if let releaseDate = album.releaseDateEstimateFormattedOptional() {
					Text(releaseDate)
						.foregroundStyle(.secondary)
						.font(.caption)
				}
			}
			
			Spacer()
			
			AvatarImage(libraryItem: album)
				.offset(y: -0.5)
				.accessibilitySortPriority(10)
		}
		.accessibilityElement(children: .combine)
		.accessibilityAddTraits(.isButton)
		.accessibilityInputLabels([album.titleFormatted()])
	}
}
final class AlbumCell: UITableViewCell {
	static let usesSwiftUI__ = 10 == 1
	
	// `AvatarDisplaying__`
	@IBOutlet var spacerSpeakerImageView: UIImageView!
	@IBOutlet var speakerImageView: UIImageView!
	
	private var rowContentAccessibilityLabel__: String? = nil
	
	@IBOutlet private var mainStack: UIStackView!
	@IBOutlet private var coverArtView: UIImageView!
	@IBOutlet private var textStack: UIStackView!
	@IBOutlet private var titleLabel: UILabel!
	@IBOutlet private var releaseDateLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		backgroundColor_set_to_clear()
		
		coverArtView.accessibilityIgnoresInvertColors = true
		// Round artwork corners
		let artViewLayer = coverArtView.layer
		artViewLayer.cornerCurve = .continuous
		artViewLayer.cornerRadius = .eight * 1/2
		
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
			coverArtView.image = representative?.coverArt(largerThanOrEqualToSizeInPoints: CGSize(
				width: widthAndHeightInPoints,
				height: widthAndHeightInPoints))
			os_signpost(.end, log: .albumsView, name: "Set cover art")
			
			titleLabel.text = album.titleFormatted()
			releaseDateLabel.text = album.releaseDateEstimateFormattedOptional()
			
			if releaseDateLabel.text == nil {
				// We couldn’t determine the album’s release date.
				textStack.spacing = 0
			} else {
				textStack.spacing = 4
			}
		}
		
		switch mode {
			case .normal:
				contentView.layer.opacity = 1 // The default value
				isUserInteractionEnabled_setTrueWithAxTrait()
			case .modal:
				backgroundColor_set_to_clear()
				contentView.layer.opacity = .oneFourth // Close to what Files pickers use
				isUserInteractionEnabled_setFalseWithAxTrait()
			case .modalTinted:
				backgroundColor = .tintColor.withAlphaComponent(.oneEighth)
				contentView.layer.opacity = .oneHalf
				isUserInteractionEnabled_setFalseWithAxTrait()
		}
		
		if !Self.usesSwiftUI__ {
			rowContentAccessibilityLabel__ = [
				titleLabel.text,
				releaseDateLabel.text,
			].compactedAndFormattedAsNarrowList()
			indicateAvatarStatus__(
				album.avatarStatus()
			)
			
			accessibilityUserInputLabels = [album.titleFormatted()]
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
		
		if !Self.usesSwiftUI__ {
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
			
			separatorInset.left = 0
			+ contentView.frame.minX
			+ mainStack.frame.minX // 16
			+ coverArtView.frame.width // 132
			+ (
				textIsHuge
				? Self.mainStackSpacingWhenHorizontal // 10
				: mainStack.spacing
			)
		}
		
		separatorInset.right = directionalLayoutMargins.trailing
	}
}
extension AlbumCell: AvatarDisplaying__ {
	func indicateAvatarStatus__(
		_ avatarStatus: AvatarStatus
	) {
		if Self.usesSwiftUI__ { return }
		
		spacerSpeakerImageView.maximumContentSizeCategory = .extraExtraExtraLarge
		speakerImageView.maximumContentSizeCategory = spacerSpeakerImageView.maximumContentSizeCategory
		
		spacerSpeakerImageView.image = UIImage(systemName: Avatar.preference.playingSFSymbolName)
		
		speakerImageView.image = avatarStatus.uiImage
		
		accessibilityLabel = [
			avatarStatus.axLabel,
			rowContentAccessibilityLabel__,
		].compactedAndFormattedAsNarrowList()
	}
}
