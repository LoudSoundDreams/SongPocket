//
//  Albums - Views.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit

final class AlbumCell: UITableViewCell {
	@IBOutlet var albumStackView: UIStackView!
	@IBOutlet var artworkImageView: UIImageView!
	@IBOutlet var textStackView: UIStackView!
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var releaseDateLabel: UILabel!
	@IBOutlet var nowPlayingIndicatorImageView: UIImageView!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		artworkImageView.accessibilityIgnoresInvertColors = true
		
		configureForTraitCollection()
	}
	
	final func configure(
		with album: Album,
		isInMovingAlbumsMode: Bool
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
		
		if isInMovingAlbumsMode {
			accessoryType = .none
		} else {
			accessoryType = .disclosureIndicator
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
