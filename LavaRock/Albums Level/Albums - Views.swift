//
//  Albums - Views.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit
import SwiftUI
import OSLog

final class MoveHereCell: UITableViewCell {
	@IBOutlet private var moveHereLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		selectedBackgroundView_add_tint()
		
		Task {
			accessibilityTraits.formUnion(.button)
		}
		
		moveHereLabel.textColor = .tintColor
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.right = directionalLayoutMargins.trailing
	}
}

final class AlbumCell: UITableViewCell {
	enum Mode {
		case normal
		case modal
		case modalTinted
	}
	
	// `AvatarDisplaying__`
	@IBOutlet var spacerSpeakerImageView: UIImageView!
	@IBOutlet var speakerImageView: UIImageView!
	
	private var rowContentAccessibilityLabel__: String? = nil
	
	@IBOutlet private var mainStack: UIStackView! // So that we can rearrange `coverArtView` and `textStack` at very large text sizes
	@IBOutlet private var coverArtView: UIImageView!
	@IBOutlet private var textStack: UIStackView!
	@IBOutlet private var titleLabel: UILabel!
	@IBOutlet private var releaseDateLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		selectedBackgroundView_add_tint()
		
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
		mode: Mode
	) {
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
		
		switch mode {
			case .normal:
				backgroundColor_set_to_clear()
				contentView.layer.opacity = 1 // The default value
				accessoryType = .disclosureIndicator
				isUserInteractionEnabled_setTrueWithAxTrait()
			case .modal:
				backgroundColor_set_to_clear()
				contentView.layer.opacity = .oneFourth // Close to what Files pickers use
				accessoryType = .none
				isUserInteractionEnabled_setFalseWithAxTrait()
			case .modalTinted:
				backgroundColor = .tintColor.withAlphaComponentOneEighth()
				contentView.layer.opacity = .oneHalf
				accessoryType = .none
				isUserInteractionEnabled_setFalseWithAxTrait()
		}
		
		rowContentAccessibilityLabel__ = [
			titleLabel.text,
			releaseDateLabel.text,
		].compactedAndFormattedAsNarrowList()
		indicateAvatarStatus__(
			album.avatarStatus()
		)
		
		accessibilityUserInputLabels = [
			titleLabel.text, // Includes “Unknown Album” if that’s what we’re showing.
		].compacted()
	}
	
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
		separatorInset.right = directionalLayoutMargins.trailing
	}
}
extension AlbumCell: AvatarDisplaying__ {
	func indicateAvatarStatus__(
		_ avatarStatus: AvatarStatus
	) {
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
