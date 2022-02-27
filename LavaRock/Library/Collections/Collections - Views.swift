//
//  Collections - Views.swift
//  LavaRock
//
//  Created by h on 2020-11-06.
//

import UIKit

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class AllowAccessCell: TintedSelectedCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
		
		configureAsButton()
	}
}
extension AllowAccessCell: CellConfiguredAsButton {
	static let buttonText = LocalizedString.allowAccessToMusic
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class LoadingCell: UITableViewCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		var configuration = UIListContentConfiguration.cell()
		configuration.text = LocalizedString.loadingEllipsis
		configuration.textProperties.color = .secondaryLabel
		contentConfiguration = configuration
		
		isUserInteractionEnabled = false
		let spinnerView = UIActivityIndicatorView()
		spinnerView.startAnimating()
		spinnerView.sizeToFit() // Without this line of code, UIKit centers the UIActivityIndicatorView at the top-left corner of the cell.
		accessoryView = spinnerView
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class NoCollectionsPlaceholderCell: UITableViewCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		var configuration = UIListContentConfiguration.cell()
		configuration.text = LocalizedString.emptyDatabasePlaceholder
		configuration.textProperties.color = .secondaryLabel
		contentConfiguration = configuration
		
		isUserInteractionEnabled = false
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class OpenMusicCell: TintedSelectedCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
		
		configureAsButton()
	}
	
	final func didSelect() {
		URL.music?.open()
	}
}
extension OpenMusicCell: CellConfiguredAsButton {
	static let buttonText = LocalizedString.openMusic
}

final class CreateCollectionCell: TintedSelectedCell {
	@IBOutlet private var newCollectionLabel: UILabel!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
		
		newCollectionLabel.textColor = .tintColor
		
		if Enabling.multicollection {
			newCollectionLabel.text = LocalizedString.newSectionButtonTitle
		}
	}
}

final class CollectionCell:
	TintedSelectedCell,
	CellHavingTransparentBackground
{
	enum Mode {
		case normal
		case modal
		case modalTinted
		
		
		case modalDisabled
	}
	
	@IBOutlet private var titleLabel: UILabel!
	@IBOutlet var nowPlayingImageView: UIImageView!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		setTransparentBackground()
	}
	
	final func configure(
		with collection: Collection,
		mode: Mode,
		accessibilityActions: [UIAccessibilityCustomAction]
	) {
		// Title
		let title: String // Don’t let this be `nil`.
		= collection.title ?? " " // Don’t let this be empty. Otherwise, when we revert combining `Collection`s before `freshenLibraryItems`, the table view vertically collapses rows for deleted `Collection`s.
		
		titleLabel.text = title
		accessibilityCustomActions = accessibilityActions
		
		switch mode {
		case .normal:
			setTransparentBackground()
			
			titleLabel.textColor = .label
			enableWithAccessibilityTrait()
		case .modal:
			setTransparentBackground()
			
			titleLabel.textColor = .label
			enableWithAccessibilityTrait()
		case .modalTinted:
			backgroundColor = .tintColor.translucentFaint()
			
			titleLabel.textColor = .label
			enableWithAccessibilityTrait()
			
			
		case .modalDisabled:
			setTransparentBackground()
			
			titleLabel.textColor = .placeholderText
			disableWithAccessibilityTrait()
		}
	}
}
extension CollectionCell: NowPlayingIndicating {}
