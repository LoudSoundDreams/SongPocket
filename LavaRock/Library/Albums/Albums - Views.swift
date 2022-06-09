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
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		tintSelectedBackgroundView()
		
		accessibilityTraits.formUnion(.button)
		
		moveHereLabel.textColor = .tintColor
	}
	
	final override func layoutSubviews() {
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
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		tintSelectedBackgroundView()
		
		removeBackground()
		
		coverArtView.accessibilityIgnoresInvertColors = true
		
		configureForTraitCollection()
	}
	
	final func configure(
		with album: Album,
		mode: Mode
	) {
		let albumTitleOptional = album.titleFormattedOptional()
		
		os_signpost(.begin, log: .albumsView, name: "Draw and set cover art")
		coverArtView.image = {
			let maxWidthAndHeight = coverArtView.bounds.width
			return album.coverArt(
				at: CGSize(
					width: maxWidthAndHeight,
					height: maxWidthAndHeight))
		}()
		os_signpost(.end, log: .albumsView, name: "Draw and set cover art")
		titleLabel.text = { () -> String in
			if let albumTitle = albumTitleOptional {
				return albumTitle
			} else {
				return Album.unknownTitlePlaceholder
			}
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
			accessoryType = .disclosureIndicator
			enableWithAccessibilityTrait()
		case .modal:
			removeBackground()
			accessoryType = .none
			disableWithAccessibilityTrait()
		case .modalTinted:
			backgroundColor = .tintColor.translucentFaint()
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
		
		accessibilityUserInputLabels = [albumTitleOptional].compactMap { $0 }
	}
	
	final override func traitCollectionDidChange(
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
	
	private var sizeCategoryIsAccessibility: Bool {
		return traitCollection.preferredContentSizeCategory.isAccessibilityCategory
	}
	
	private func configureForTraitCollection() {
		if sizeCategoryIsAccessibility {
			mainStack.axis = .vertical
			mainStack.alignment = .leading
			mainStack.spacing = UIStackView.spacingUseSystem
		} else {
			mainStack.axis = .horizontal
			mainStack.alignment = .center
			mainStack.spacing = 12
		}
	}
	
	final override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.left = 0
		+ contentView.frame.minX
		+ mainStack.frame.minX // 16
		+ coverArtView.frame.width // 132
		+ (sizeCategoryIsAccessibility ? 12 : mainStack.spacing /*12*/)
		separatorInset.right = directionalLayoutMargins.trailing
	}
}
extension AlbumCell:
	PlayheadReflectable,
	CellTintingWhenSelected,
	CellHavingTransparentBackground
{}
