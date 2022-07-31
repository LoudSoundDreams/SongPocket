//
//  Albums - Views.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit
import OSLog

final class MoveHereCell: UITableViewCell {
	@IBOutlet private var moveHereLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		tintSelectedBackgroundView()
		
		accessibilityTraits.formUnion(.button)
		
		moveHereLabel.textColor = .tintColor
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.right = directionalLayoutMargins.trailing
	}
}
extension MoveHereCell: CellTintingWhenSelected {}

final class AlbumCell: UITableViewCell {
	enum Mode {
		case normal
		case modal
		case modalTinted
	}
	
	// `PlayheadReflectable`
	@IBOutlet var spacerSpeakerImageView: UIImageView!
	@IBOutlet var speakerImageView: UIImageView!
	var bodyOfAccessibilityLabel: String? = nil
	
	@IBOutlet private var mainStack: UIStackView! // So that we can rearrange `coverArtView` and `textStack` at very large text sizes.
	@IBOutlet private var coverArtView: UIImageView!
	@IBOutlet private var textStack: UIStackView!
	@IBOutlet private var titleLabel: UILabel!
	@IBOutlet private var releaseDateLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		tintSelectedBackgroundView()
		
		removeBackground()
		
		coverArtView.accessibilityIgnoresInvertColors = true
		
		configureForTraitCollection()
	}
	
	func configure(
		with album: Album,
		mode: Mode
	) {
		let representative = album.representativeSongMetadatum() // Can be `nil`
		
		os_signpost(.begin, log: .albumsView, name: "Set cover art")
		coverArtView.image = {
			os_signpost(.begin, log: .albumsView, name: "Draw cover art")
			defer {
				os_signpost(.end, log: .albumsView, name: "Draw cover art")
			}
			let widthAndHeightInPoints = coverArtView.bounds.width
			return representative?.coverArt(sizeInPoints: CGSize(
				width: widthAndHeightInPoints,
				height: widthAndHeightInPoints))
		}()
		os_signpost(.end, log: .albumsView, name: "Set cover art")
		
		titleLabel.text = { () -> String in
			return album.representativeTitleFormattedOptional() ?? Album.unknownTitlePlaceholder
		}()
		
		releaseDateLabel.text = album.releaseDateEstimateFormattedOptional()
		 
		if releaseDateLabel.text == nil {
			// We couldn’t determine the album’s release date.
			textStack.spacing = 0
		} else {
			textStack.spacing = 4
		}
		
		switch mode {
		case .normal:
			removeBackground()
			contentView.layer.opacity = 1 // The default value
			accessoryType = .disclosureIndicator
			enableWithAccessibilityTrait()
		case .modal:
			removeBackground()
			contentView.layer.opacity = .oneFourth // Close to what Files pickers use
			accessoryType = .none
			disableWithAccessibilityTrait()
		case .modalTinted:
			backgroundColor = .tintColor.translucentFaint()
			contentView.layer.opacity = .oneHalf
			accessoryType = .none
			disableWithAccessibilityTrait()
		}
		
		bodyOfAccessibilityLabel = [
			titleLabel.text,
			releaseDateLabel.text,
		].compactedAndFormattedAsNarrowList()
		
		reflectPlayhead(
			containsPlayhead: album.containsPlayhead(),
			bodyOfAccessibilityLabel: bodyOfAccessibilityLabel)
		
		// For Voice Control, only include the album title.
		// Include “Unknown Album” if that’s what we’re showing.
		accessibilityUserInputLabels = [
			titleLabel.text,
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
			configureForTraitCollection()
		}
	}
	
	private var textIsHuge: Bool {
		return traitCollection.preferredContentSizeCategory.isAccessibilityCategory
	}
	
	private func configureForTraitCollection() {
		if textIsHuge {
			mainStack.axis = .vertical
			mainStack.alignment = .leading
			mainStack.spacing = UIStackView.spacingUseSystem
		} else {
			mainStack.axis = .horizontal
			mainStack.alignment = .center
			mainStack.spacing = 12
		}
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.left = 0
		+ contentView.frame.minX
		+ mainStack.frame.minX // 16
		+ coverArtView.frame.width // 132
		+ (textIsHuge ? 12 : mainStack.spacing /*12*/)
		separatorInset.right = directionalLayoutMargins.trailing
	}
}
extension AlbumCell:
	PlayheadReflectable,
	CellTintingWhenSelected,
	CellHavingTransparentBackground
{}
