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
	
	private func configure() {
		var configuration = UIListContentConfiguration.cell()
		configuration.text = LocalizedString.allowAccessToMusic
		configuration.textProperties.color = .tintColor(ifiOS14: AccentColor.savedPreference()) // As of iOS 15.1 developer beta 3, `UIColor.tintColor` dims and undims with animations when we present and dismiss a modal view. It also automatically matches `window?.tintColor`, even if you don't override `tintColorDidChange()`.
		// - `self.tintColor`dims and undims with animations when we present and dismiss a modal view. It also automatically matches `window?.tintColor`, even if you don't override `tintColorDidChange()`.
		// - Don't use `AccentColor.savedPreference().uiColor` or `window?.tintColor`, because when we have a modal view presented, they aren't dimmed.
		// - Also don't use `contentView.tintColor`, because when we present a modal view, it doesn't dim, although it is dimmed if you change `window.tintColor` later.
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
	
	private func configure() {
		var configuration = UIListContentConfiguration.cell()
		configuration.text = LocalizedString.openMusic
		configuration.textProperties.color = .tintColor(ifiOS14: AccentColor.savedPreference())
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
	enum Mode {
		case normal
		case movingAlbumsModeAndNotSourceOfAlbums
		case movingAlbumsModeAndSourceOfAlbums
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
			if FeatureFlag.multicollection {
				backgroundColor = nil
			} else {
				titleLabel.textColor = .label
				enableWithAccessibilityTrait()
			}
			accessibilityCustomActions = [renameFocusedCollectionAction]
		case .movingAlbumsModeAndNotSourceOfAlbums:
			if FeatureFlag.multicollection {
				backgroundColor = nil
			} else {
				titleLabel.textColor = .label
				enableWithAccessibilityTrait()
			}
			accessibilityCustomActions = []
		case .movingAlbumsModeAndSourceOfAlbums:
			if FeatureFlag.multicollection {
				backgroundColor = .tintColorTranslucent(ifiOS14: AccentColor.savedPreference())
			} else {
				titleLabel.textColor = .placeholderText // A proper way to make cells look disabled would be better. This is slightly different from the old cell.textLabel.isEnabled = false.
				disableWithAccessibilityTrait()
			}
			accessibilityCustomActions = []
		}
	}
}

extension CollectionCell: NowPlayingIndicating {
}
