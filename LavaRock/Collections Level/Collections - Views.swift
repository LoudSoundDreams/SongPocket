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
		
		configure()
	}
	
	private func configure() {
		var configuration = UIListContentConfiguration.cell()
		configuration.text = LocalizedString.allowAccessToMusic
		if #available(iOS 15, *) {
			// Don't confuse this with `self.tintColor`.
			configuration.textProperties.color = UIColor.tintColor // As of iOS 15.1 developer beta 3, this dims and undims with animations when we present and dismiss a modal view. It also automatically matches `window?.tintColor`, even if you don't override `tintColorDidChange()`.
		} else {
			// Don't confuse this with `UIColor.tintColor`.
			configuration.textProperties.color = self.tintColor // Dims and undims when we present and dismiss a modal view, but instantaneously and only after the animation completes.
			// As of iOS 15.1 developer beta 3:
			// - Don't use `AccentColor.savedPreference().uiColor` or `window?.tintColor`, because when we have a modal view presented, they aren't dimmed.
			// - Also don't use `contentView.tintColor`, because when we present a modal view, it doesn't dim, although it is dimmed if you change `window.tintColor` later.
		}
		contentConfiguration = configuration
	}
	
	final override func tintColorDidChange() {
		super.tintColorDidChange()
		
		if #available(iOS 15, *) {
			// See comment in `configure()`.
		} else {
			configure()
		}
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
	
	private func configure() {
		var configuration = UIListContentConfiguration.cell()
		configuration.text = LocalizedString.openMusic
		if #available(iOS 15, *) { // See comments in `AllowAccessCell`.
			configuration.textProperties.color = UIColor.tintColor
		} else {
			configuration.textProperties.color = self.tintColor
		}
		contentConfiguration = configuration
	}
	
	final override func tintColorDidChange() {
		super.tintColorDidChange()
		
		if #available(iOS 15, *) { // See comments in `AllowAccessCell`.
		} else {
			configure()
		}
	}
	
	final func didSelect() {
		URL.music?.open()
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
