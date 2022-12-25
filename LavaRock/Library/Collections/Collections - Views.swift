//
//  Collections - Views.swift
//  LavaRock
//
//  Created by h on 2020-11-06.
//

import UIKit

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class AllowAccessCell: UITableViewCell {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		tintSelectedBackgroundView()
		
		configureAsButton()
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.right = directionalLayoutMargins.trailing
	}
}
extension AllowAccessCell: CellTintingWhenSelected {}
extension AllowAccessCell: CellConfigurableAsButton {
	static let buttonText = LRString.allowAccessToMusic
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class LoadingCell: UITableViewCell {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		var content = UIListContentConfiguration.cell()
		content.text = LRString.loadingEllipsis
		content.textProperties.color = .secondaryLabel
		contentConfiguration = content
		
		isUserInteractionEnabled = false
		let spinnerView = UIActivityIndicatorView()
		spinnerView.startAnimating()
		spinnerView.sizeToFit() // Without this line of code, UIKit centers the UIActivityIndicatorView at the top-left corner of the cell.
		accessoryView = spinnerView
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.right = directionalLayoutMargins.trailing
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class NoCollectionsPlaceholderCell: UITableViewCell {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		var content = UIListContentConfiguration.cell()
		content.text = LRString.emptyDatabasePlaceholder
		content.textProperties.color = .secondaryLabel
		contentConfiguration = content
		
		isUserInteractionEnabled = false
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.right = directionalLayoutMargins.trailing
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class OpenMusicCell: UITableViewCell {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		tintSelectedBackgroundView()
		
		configureAsButton()
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.right = directionalLayoutMargins.trailing
	}
}
extension OpenMusicCell: CellTintingWhenSelected {}
extension OpenMusicCell: CellConfigurableAsButton {
	static let buttonText = LRString.openMusic
}

final class CreateCollectionCell: UITableViewCell {
	@IBOutlet private var newCollectionLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		tintSelectedBackgroundView()
		
		Task {
			accessibilityTraits.formUnion(.button)
		}
		
		newCollectionLabel.text = LRString.newCollection_buttonTitle
		newCollectionLabel.textColor = .tintColor
	}
	
	override func layoutSubviews() {
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
	static let usesUIKitAccessibility__ = true
	var rowContentAccessibilityLabel__: String? = nil
	
	@IBOutlet private var titleLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		tintSelectedBackgroundView()
		
		removeBackground()
	}
	
	func configure(
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
			
			contentView.layer.opacity = 1
			enableWithAccessibilityTrait()
		case .modal:
			removeBackground()
			
			contentView.layer.opacity = 1
			enableWithAccessibilityTrait()
		case .modalTinted:
			backgroundColor = .tintColor.withAlphaComponentOneEighth()
			
			contentView.layer.opacity = 1
			enableWithAccessibilityTrait()
			
			
		case .modalDisabled:
			removeBackground()
			
			contentView.layer.opacity = .oneFourth
			disableWithAccessibilityTrait()
		}
		
		rowContentAccessibilityLabel__ = titleLabel.text
		
		reflectPlayhead(
			containsPlayhead: collection.containsPlayhead(),
			rowContentAccessibilityLabel__: rowContentAccessibilityLabel__)
		
		// Exclude the now-playing marker’s accessibility label.
		accessibilityUserInputLabels = [
			titleLabel.text,
		].compacted()
	}
	
	override func layoutSubviews() {
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
