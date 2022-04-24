//
//  Collections - Views.swift
//  LavaRock
//
//  Created by h on 2020-11-06.
//

import UIKit

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class AllowAccessCell: UITableViewCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		tintSelectedBackgroundView()
		
		configureAsButton()
	}
	
	final override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.right = directionalLayoutMargins.trailing
	}
}
extension AllowAccessCell: CellTintingWhenSelected {}
extension AllowAccessCell: CellConfigurableAsButton {
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
	
	final override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.right = directionalLayoutMargins.trailing
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
	
	final override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.right = directionalLayoutMargins.trailing
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class OpenMusicCell: UITableViewCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		tintSelectedBackgroundView()
		
		configureAsButton()
	}
	
	final override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.right = directionalLayoutMargins.trailing
	}
	
	final func didSelect() {
		URL.music?.open()
	}
}
extension OpenMusicCell: CellTintingWhenSelected {}
extension OpenMusicCell: CellConfigurableAsButton {
	static let buttonText = LocalizedString.openMusic
}

final class CreateCollectionCell: UITableViewCell {
	@IBOutlet private var newCollectionLabel: UILabel!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		tintSelectedBackgroundView()
		
		accessibilityTraits.formUnion(.button)
		
		newCollectionLabel.textColor = .tintColor
		
		if Enabling.multicollection {
			newCollectionLabel.text = LocalizedString.newSectionButtonTitle
		}
	}
	
	final override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.right = directionalLayoutMargins.trailing
	}
}
extension CreateCollectionCell: CellTintingWhenSelected {}

final class CollectionCell: UITableViewCell {
	enum Mode {
		case normal
		case modal
		case modalTinted
		
		
		case modalDisabled
	}
	
	// `PlayheadReflectable`
	@IBOutlet var spacerSpeakerImageView: UIImageView!
	@IBOutlet var speakerImageView: UIImageView!
	
	@IBOutlet private var titleLabel: UILabel!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		tintSelectedBackgroundView()
		
		removeBackground()
	}
	
	final func configure(
		with collection: Collection,
		mode: Mode,
		accessibilityActions: [UIAccessibilityCustomAction]
	) {
		titleLabel.text = { () -> String in
			return collection.title ?? " " // Don’t let this be empty. Otherwise, when we revert combining `Collection`s before `freshenLibraryItems`, the table view vertically collapses rows for deleted `Collection`s.
		}()
		accessibilityCustomActions = accessibilityActions
		
		switch mode {
		case .normal:
			removeBackground()
			
			titleLabel.textColor = .label
			enableWithAccessibilityTrait()
		case .modal:
			removeBackground()
			
			titleLabel.textColor = .label
			enableWithAccessibilityTrait()
		case .modalTinted:
			backgroundColor = .tintColor.translucentFaint()
			
			titleLabel.textColor = .label
			enableWithAccessibilityTrait()
			
			
		case .modalDisabled:
			removeBackground()
			
			titleLabel.textColor = .placeholderText
			disableWithAccessibilityTrait()
		}
		
		reflectPlayhead(containsPlayhead: collection.containsPlayhead())
	}
	
	final override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.left = 0
		+ contentView.frame.minX
		+ titleLabel.frame.minX
		separatorInset.right = directionalLayoutMargins.trailing
	}
}
extension CollectionCell:
	PlayheadReflectable,
	CellTintingWhenSelected,
	CellHavingTransparentBackground
{}
