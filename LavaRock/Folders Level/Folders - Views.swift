//
//  Folders - Views.swift
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
		
		contentConfiguration = UIHostingConfiguration {
			Text(LRString.allowAccessToMusic)
				.foregroundStyle(Color.accentColor)
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
final class NoFoldersPlaceholderCell: UITableViewCell {
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
		
		contentConfiguration = UIHostingConfiguration {
			LabeledContent {
				Image(systemName: "arrow.up.forward.app")
					.foregroundStyle(Color.accentColor)
			} label: {
				Text(LRString.appleMusic)
					.foregroundStyle(Color.accentColor)
					.accessibilityAddTraits(.isButton)
			}
		}
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.right = directionalLayoutMargins.trailing
	}
}

final class CreateFolderCell: UITableViewCell {
	private static let usesSwiftUI__ = 10 == 1
	
	@IBOutlet private var newFolderLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		guard !Self.usesSwiftUI__ else { return }
		
		newFolderLabel.text = LRString.newFolder
		newFolderLabel.textColor = .tintColor
		
		accessibilityTraits.formUnion(.button)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.right = directionalLayoutMargins.trailing
	}
}

final class FolderCell: UITableViewCell {
	private static let usesSwiftUI__ = 10 == 1
	
	// `AvatarDisplaying__`
	@IBOutlet var spacerSpeakerImageView: UIImageView!
	@IBOutlet var speakerImageView: UIImageView!
	
	private var rowContentAccessibilityLabel__: String? = nil
	
	@IBOutlet private var titleLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		backgroundColor_set_to_clear()
	}
	
	func configure(
		with folder: Collection,
		mode: FolderRowMode
	) {
		if Self.usesSwiftUI__ {
			
			contentConfiguration = UIHostingConfiguration {
				FolderRow(
					folder: folder,
					mode: mode
				)
			}
			
		} else {
			
			titleLabel.text = folder.title ?? " " // Don’t let this be empty. Otherwise, when we revert combining folders before `freshenLibraryItems`, the table view vertically collapses rows for deleted folders.
			contentView.layer.opacity = {
				if case FolderRowMode.modalDisabled = mode {
					return .oneFourth
				} else {
					return 1
				}
			}()
			
			rowContentAccessibilityLabel__ = titleLabel.text
			indicateAvatarStatus__(
				folder.avatarStatus()
			)
			
			// Exclude the now-playing marker.
			accessibilityUserInputLabels = [
				folder.title, // Can be `nil`
			].compacted()
			
		}
		
		switch mode {
			case .normal(let actions):
				backgroundColor_set_to_clear()
				
				isUserInteractionEnabled_setTrueWithAxTrait()
				accessibilityCustomActions = actions
			case .modal:
				backgroundColor_set_to_clear()
				
				isUserInteractionEnabled_setTrueWithAxTrait()
				accessibilityCustomActions = []
			case .modalTinted:
				backgroundColor = .tintColor.withAlphaComponent(.oneEighth)
				
				isUserInteractionEnabled_setTrueWithAxTrait()
				accessibilityCustomActions = []
			case .modalDisabled:
				backgroundColor_set_to_clear()
				
				isUserInteractionEnabled_setFalseWithAxTrait()
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
extension FolderCell: AvatarDisplaying__ {
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
