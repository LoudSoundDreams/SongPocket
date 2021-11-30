//
//  Albums - Views.swift
//  LavaRock
//
//  Created by h on 2020-07-10.
//

import UIKit

final class MoveHereCell: UITableViewCell {
	@IBOutlet private var moveHereLabel: UILabel!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
		
		configure()
	}
	
	private func configure() {
//		var configuration = UIListContentConfiguration.cell()
//		configuration.text = LocalizedString.moveHere
//		configuration.textProperties.font = .preferredFont(
//			forTextStyle: .headline,
//			compatibleWith: traitCollection)
//		configuration.textProperties.color = .tintColor(ifiOS14: AccentColor.savedPreference())
//		contentConfiguration = configuration
		
		moveHereLabel.textColor = .tintColor(ifiOS14: AccentColor.savedPreference())
	}
	
	final override func tintColorDidChange() {
		super.tintColorDidChange()
		
		if #available(iOS 15, *) { // See comments in `AllowAccessCell`.
		} else {
			configure()
		}
	}
}

final class AlbumCell: UITableViewCell {
	enum Mode {
		case normal
		case modalNotTinted
		case modalTinted
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
		let artworkImage = album.artworkImage( // Can be nil
			at: CGSize(
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
			backgroundColor = nil
			accessoryType = .disclosureIndicator
			enableWithAccessibilityTrait()
		case .modalNotTinted:
			backgroundColor = nil
			accessoryType = .none
			disableWithAccessibilityTrait()
		case .modalTinted:
			backgroundColor = .tintColorTranslucent(ifiOS14: AccentColor.savedPreference())
			accessoryType = .none
			disableWithAccessibilityTrait()
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
