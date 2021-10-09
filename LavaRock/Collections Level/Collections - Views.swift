//
//  Collections - Views.swift
//  LavaRock
//
//  Created by h on 2020-11-06.
//

import UIKit
import CoreData

final class AllCollectionsCell: UITableViewCell {
	@IBOutlet var allLabel: UILabel!
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class AllowAccessCell: UITableViewCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		accessibilityTraits.formUnion(.button)
	}
	
	final func configure(with accentColor: AccentColor) {
		var configuration = UIListContentConfiguration.cell()
		configuration.text = LocalizedString.allowAccessToMusic
		configuration.textProperties.color = accentColor.uiColor
		contentConfiguration = configuration
	}
}

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class LoadingCell: UITableViewCell {
	final override func awakeFromNib() {
		super.awakeFromNib()
		
		var configuration = UIListContentConfiguration.cell()
		configuration.text = LocalizedString.loadingWithEllipsis
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
		configuration.text = LocalizedString.noCollectionsPlaceholder
		configuration.textProperties.font = .preferredFont(forTextStyle: .body)
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
	}
	
	final func configure(with accentColor: AccentColor) {
		var configuration = UIListContentConfiguration.cell()
		configuration.text = LocalizedString.openMusic
		configuration.textProperties.color = accentColor.uiColor
		contentConfiguration = configuration
	}
}

final class CollectionCell: UITableViewCell {
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var nowPlayingIndicatorImageView: UIImageView!
	
	final func configure(
		with collection: Collection,
		isMovingAlbumsFromCollectionWith idOfSourceCollection: NSManagedObjectID?,
		renameFocusedCollectionAction: UIAccessibilityCustomAction
	) {
		// Title
		let collectionTitle = collection.title
		
		titleLabel.text = collectionTitle
		
		if let idOfSourceCollection = idOfSourceCollection {
			// This cell is appearing in "moving Albums" mode.
			if idOfSourceCollection == collection.objectID {
				titleLabel.textColor = .placeholderText // A proper way to make cells look disabled would be better. This is slightly different from the old cell.textLabel.isEnabled = false.
				disableWithAccessibilityTrait()
			} else {
				titleLabel.textColor = .label
				enableWithAccessibilityTrait()
			}
			accessibilityCustomActions = []
		} else {
			titleLabel.textColor = .label
			enableWithAccessibilityTrait()
			
			accessibilityCustomActions = [renameFocusedCollectionAction]
		}
	}
}

extension CollectionCell: NowPlayingIndicating {
}
