//
//  Collections - Views.swift
//  LavaRock
//
//  Created by h on 2020-11-06.
//

import UIKit
import SwiftUI

// The cell in the storyboard is completely default except for the reuse identifier and custom class.
final class AllowAccessCell: UITableViewCell {
	override func awakeFromNib() {
		super.awakeFromNib()
		
		selectedBackgroundView_add_tint()
		
		contentConfiguration = UIHostingConfiguration {
			Text(LRString.allowAccessToMusic)
				.foregroundColor(.accentColor)
				.accessibilityAddTraits(.isButton)
		}
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.right = directionalLayoutMargins.trailing
	}
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
		
		selectedBackgroundView_add_tint()
		
		contentConfiguration = UIHostingConfiguration {
			Text(LRString.appleMusic)
				.foregroundColor(.accentColor)
				.accessibilityAddTraits(.isButton)
		}
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.right = directionalLayoutMargins.trailing
	}
}

final class CreateCollectionCell: UITableViewCell {
	private static let usesSwiftUI__ = 10 == 1
	
	@IBOutlet private var newCollectionLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		selectedBackgroundView_add_tint()
		
		guard !Self.usesSwiftUI__ else { return }
		
		newCollectionLabel.text = LRString.newFolder
		newCollectionLabel.textColor = .tintColor
		
		accessibilityTraits.formUnion(.button)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.right = directionalLayoutMargins.trailing
	}
}

final class CollectionCell: UITableViewCell {
	private static let usesSwiftUI__ = 10 == 1
	
	// `AvatarDisplaying__`
	@IBOutlet var spacerSpeakerImageView: UIImageView!
	@IBOutlet var speakerImageView: UIImageView!
	
	private var rowContentAccessibilityLabel__: String? = nil
	
	@IBOutlet private var titleLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		selectedBackgroundView_add_tint()
		
		backgroundColor_set_to_clear()
	}
	
	func configure(
		with collection: Collection,
		mode: FolderRowMode
	) {
		if Self.usesSwiftUI__ {
			
			contentConfiguration = UIHostingConfiguration {
				FolderRow(
					collection: collection,
					mode: mode
				)
			}
			
		} else {
			
			titleLabel.text = collection.title ?? " " // Don’t let this be empty. Otherwise, when we revert combining `Collection`s before `freshenLibraryItems`, the table view vertically collapses rows for deleted `Collection`s.
			contentView.layer.opacity = {
				if case FolderRowMode.modalDisabled = mode {
					return .oneFourth
				} else {
					return 1
				}
			}()
			
			rowContentAccessibilityLabel__ = titleLabel.text
			indicateAvatarStatus__(
				collection.avatarStatus()
			)
			
			// Exclude the now-playing marker.
			accessibilityUserInputLabels = [
				collection.title, // Can be `nil`
			].compacted()
			
		}
		
		switch mode {
		case .normal(let actions):
			backgroundColor_set_to_clear()
			
			enableWithAccessibilityTrait()
			accessibilityCustomActions = actions
		case .modal:
			backgroundColor_set_to_clear()
			
			enableWithAccessibilityTrait()
			accessibilityCustomActions = []
		case .modalTinted:
			backgroundColor = .tintColor.withAlphaComponentOneEighth()
			
			enableWithAccessibilityTrait()
			accessibilityCustomActions = []
		case .modalDisabled:
			backgroundColor_set_to_clear()
			
			disableWithAccessibilityTrait()
			accessibilityCustomActions = []
		}
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		guard !Self.usesSwiftUI__ else { return }
		
		separatorInset.left = 0
		+ contentView.frame.minX
		+ titleLabel.frame.minX
		separatorInset.right = directionalLayoutMargins.trailing
	}
}
extension CollectionCell: AvatarDisplaying__ {
	func indicateAvatarStatus__(
		_ avatarStatus: AvatarStatus
	) {
		guard !Self.usesSwiftUI__ else { return }
		
		spacerSpeakerImageView.maximumContentSizeCategory = .extraExtraExtraLarge
		speakerImageView.maximumContentSizeCategory = spacerSpeakerImageView.maximumContentSizeCategory
		
		spacerSpeakerImageView.image = UIImage(systemName: Avatar.preference.playingSFSymbolName)
		
		speakerImageView.image = avatarStatus.uiImage
		
		accessibilityLabel = [
			avatarStatus.axLabel,
			rowContentAccessibilityLabel__,
		].compactedAndFormattedAsNarrowList()
	}
}
