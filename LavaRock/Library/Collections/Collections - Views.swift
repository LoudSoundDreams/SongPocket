//
//  Collections - Views.swift
//  LavaRock
//
//  Created by h on 2020-11-06.
//

import UIKit
import CoreData

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class AllowAccessCell: TintedSelectedCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
		
		configureAsCellActingAsButton()
	}
}
extension AllowAccessCell: CellActingAsButton {
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
		
		configureAsCellActingAsButton()
	}
	
	final func didSelect() {
		URL.music?.open()
	}
}
extension OpenMusicCell: CellActingAsButton {
	static let buttonText = LocalizedString.openMusic
}

final class CreateCollectionCell: TintedSelectedCell {
	@IBOutlet private var newCollectionLabel: UILabel!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
		
		newCollectionLabel.textColor = .tintColor
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
		
		setNormalBackground()
	}
	
	final func configure(
		with collection: Collection,
		mode: Mode,
		renameFocusedCollectionAction: UIAccessibilityCustomAction // TO DO: Pass in `nil` if you don't want accessibility custom actions.
	) {
		// Title
		let collectionTitle = collection.title
		
		titleLabel.text = collectionTitle
		
		switch mode {
		case .normal:
			accessibilityCustomActions = [renameFocusedCollectionAction]
			setNormalBackground()
			
			titleLabel.textColor = .label
			enableWithAccessibilityTrait()
		case .modal:
			accessibilityCustomActions = []
			setNormalBackground()
			
			titleLabel.textColor = .label
			enableWithAccessibilityTrait()
		case .modalTinted:
			accessibilityCustomActions = []
			backgroundColor = .tintColor.translucentFaint() // Note: `backgroundColor = nil` sets a transparent background; `backgroundView = nil` sets the default background.
			
			titleLabel.textColor = .label
			enableWithAccessibilityTrait()
			
			
		case .modalDisabled:
			accessibilityCustomActions = []
			setNormalBackground()
			
			titleLabel.textColor = .placeholderText
			disableWithAccessibilityTrait()
		}
	}
}

extension CollectionCell: NowPlayingIndicating {
}
