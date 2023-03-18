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
			Text(LRString.openMusic)
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
		
		if !Self.usesSwiftUI__ {
			Task {
				accessibilityTraits.formUnion(.button)
			}
			
			newCollectionLabel.text = LRString.newFolder
			newCollectionLabel.textColor = .tintColor
		}
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.right = directionalLayoutMargins.trailing
	}
}

final class CollectionCell: UITableViewCell {
	private static let usesSwiftUI__ = 10 == 1
	
	enum Mode {
		case normal([UIAccessibilityCustomAction])
		case modal
		case modalTinted
		case modalDisabled
	}
	
	// `AvatarDisplaying`
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
		mode: Mode
	) {
		if Self.usesSwiftUI__ {
			
		} else {
			
			titleLabel.text = collection.title ?? " " // Don’t let this be empty. Otherwise, when we revert combining `Collection`s before `freshenLibraryItems`, the table view vertically collapses rows for deleted `Collection`s.
			switch mode {
			case .normal(let actions):
				backgroundColor_set_to_clear()
				
				contentView.layer.opacity = 1
				enableWithAccessibilityTrait()
				accessibilityCustomActions = actions
			case .modal:
				backgroundColor_set_to_clear()
				
				contentView.layer.opacity = 1
				enableWithAccessibilityTrait()
				accessibilityCustomActions = []
			case .modalTinted:
				backgroundColor = .tintColor.withAlphaComponentOneEighth()
				
				contentView.layer.opacity = 1
				enableWithAccessibilityTrait()
				accessibilityCustomActions = []
			case .modalDisabled:
				backgroundColor_set_to_clear()
				
				contentView.layer.opacity = .oneFourth
				disableWithAccessibilityTrait()
				accessibilityCustomActions = []
			}
			
			rowContentAccessibilityLabel__ = titleLabel.text
			reflectPlayhead(
				containsPlayhead: collection.containsPlayhead()
			)
			
			// Exclude the now-playing marker’s accessibility label.
			if !Self.usesSwiftUI__ {
				accessibilityUserInputLabels = [
					titleLabel.text,
				].compacted()
			}
			
		}
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.left = 0
		+ contentView.frame.minX
		+ titleLabel.frame.minX
		separatorInset.right = directionalLayoutMargins.trailing
	}
}
extension CollectionCell: AvatarDisplaying {
	func reflectPlayhead(
		containsPlayhead: Bool
	) {
		freshen_avatar_imageView(
			containsPlayhead: containsPlayhead)
		if !Self.usesSwiftUI__ {
			accessibilityLabel = create_accessibilityLabel(	
				containsPlayhead: containsPlayhead,
				rowContentAccessibilityLabel__: rowContentAccessibilityLabel__)
		}
		
	}
}
