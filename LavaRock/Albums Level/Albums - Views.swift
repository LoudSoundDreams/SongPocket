//
//  Albums - Views.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit

final class AlbumCell: UITableViewCell {
	enum Mode {
		case normal
		case modalNotTinted
		case modalTinted
//		case movingAlbumsModeAndNotBeingMoved
//		case movingAlbumsModeAndBeingMoved
	}
	
	@IBOutlet private var albumStackView: UIStackView!
	@IBOutlet private var artworkImageView: UIImageView!
	@IBOutlet private var textStackView: UIStackView!
	@IBOutlet private var titleLabel: UILabel!
	@IBOutlet private var releaseDateLabel: UILabel!
	@IBOutlet var nowPlayingIndicatorImageView: UIImageView!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		artworkImageView.accessibilityIgnoresInvertColors = true
		
		configureForTraitCollection()
	}
	
	final func configure(
		with album: Album,
		mode: Mode
	) {
		// Artwork
		let maxWidthAndHeight = artworkImageView.bounds.width
		let artworkImage = album.artworkImage(at: CGSize( // Can be nil
			width: maxWidthAndHeight,
			height: maxWidthAndHeight))
		
		// Title
		let title: String // Don't let this be nil.
		= album.titleFormattedOrPlaceholder()
		
		// Release date
		let releaseDateString = album.releaseDateEstimateFormatted() // Can be nil
		
		artworkImageView.image = artworkImage
		titleLabel.text = title
		releaseDateLabel.text = releaseDateString
		 
		if releaseDateString == nil {
			// We couldn't determine the album's release date.
			textStackView.spacing = 0
		} else {
			textStackView.spacing = 4
		}
		
		switch mode {
		case .normal:
//			if FeatureFlag.multicollection {
				backgroundColor = nil
//			}
			accessoryType = .disclosureIndicator
		case .modalNotTinted:
//		case .movingAlbumsModeAndNotBeingMoved:
//			if FeatureFlag.multicollection {
				backgroundColor = nil
//			}
			accessoryType = .none
		case .modalTinted:
//		case .movingAlbumsModeAndBeingMoved:
//			if FeatureFlag.multicollection {
				backgroundColor = .tintColorTranslucent(ifiOS14: AccentColor.savedPreference())
//			}
			accessoryType = .none
		}
		
		accessibilityUserInputLabels = [title]
	}
	
	private func configureForTraitCollection() {
		if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
			albumStackView.axis = .vertical
			albumStackView.alignment = .leading
			albumStackView.spacing = UIStackView.spacingUseSystem
		} else {
			albumStackView.axis = .horizontal
			albumStackView.alignment = .center
			albumStackView.spacing = 12
		}
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
}

extension AlbumCell: NowPlayingIndicating {
}
