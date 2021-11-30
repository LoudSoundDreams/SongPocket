//
//  Collections - Views.swift
//  LavaRock
//
//  Created by h on 2020-11-06.
//

import UIKit
import CoreData

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class AllowAccessCell: UITableViewCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
		
		configure()
	}
	
	final override func tintColorDidChange() {
		super.tintColorDidChange()
		
		reflectAccentColor()
	}
}
extension AllowAccessCell: ButtonCell {
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
final class OpenMusicCell: UITableViewCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
		
		configure()
	}
	
	final override func tintColorDidChange() {
		super.tintColorDidChange()
		
		reflectAccentColor()
	}
	
	final func didSelect() {
		URL.music?.open()
	}
}
extension OpenMusicCell: ButtonCell {
	static let buttonText = LocalizedString.openMusic
}

final class CreateCollectionCell: UITableViewCell {
	@IBOutlet private var newCollectionLabel: UILabel!
	
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
		
		configure()
	}
	
	private func configure() {
//		var configuration = UIListContentConfiguration.cell()
//		configuration.text = LocalizedString.newCollectionButtonTitle
//		configuration.textProperties.color = .tintColor(ifiOS14: AccentColor.savedPreference())
//		contentConfiguration = configuration
		
		newCollectionLabel.textColor = .tintColor(ifiOS14: AccentColor.savedPreference())
	}
	
	final override func tintColorDidChange() {
		super.tintColorDidChange()
		
		if #available(iOS 15, *) {
		} else {
			configure()
		}
	}
}

final class CollectionCell: UITableViewCell {
	enum Mode {
		case normal
		case modal
		case modalTinted
		
		
		case modalDisabled
	}
	
	@IBOutlet private var titleLabel: UILabel!
	@IBOutlet var nowPlayingIndicatorImageView: UIImageView!
	
	final func configure(
		with collection: Collection,
		mode: Mode,
		renameFocusedCollectionAction: UIAccessibilityCustomAction
	) {
		// Title
		let collectionTitle = collection.title
		
		titleLabel.text = collectionTitle
		
		switch mode {
		case .normal:
			accessibilityCustomActions = [renameFocusedCollectionAction]
			backgroundColor = nil
			
			titleLabel.textColor = .label
			enableWithAccessibilityTrait()
		case .modal:
			accessibilityCustomActions = []
			backgroundColor = nil
			
			titleLabel.textColor = .label
			enableWithAccessibilityTrait()
		case .modalTinted:
			accessibilityCustomActions = []
			backgroundColor = .tintColorTranslucent(ifiOS14: AccentColor.savedPreference())
			
			titleLabel.textColor = .label
			enableWithAccessibilityTrait()
			
			
		case .modalDisabled:
			accessibilityCustomActions = []
			backgroundColor = nil
			
			titleLabel.textColor = .placeholderText // A proper way to make cells look disabled would be better. This is slightly different from the old cell.textLabel.isEnabled = false.
			disableWithAccessibilityTrait()
		}
	}
}

extension CollectionCell: NowPlayingIndicating {
}
