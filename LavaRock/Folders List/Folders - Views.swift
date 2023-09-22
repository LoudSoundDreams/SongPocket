//
//  Folders - Views.swift
//  LavaRock
//
//  Created by h on 2020-11-06.
//

import UIKit
import SwiftUI

final class FolderCell: UITableViewCell {
	static let usesSwiftUI__ = 10 == 1
	
	@IBOutlet var spacerSpeakerImageView: UIImageView!
	@IBOutlet var speakerImageView: UIImageView!
	var rowContentAccessibilityLabel__: String? = nil
	
	@IBOutlet private var titleLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		backgroundColor = .clear
		
		if !Self.usesSwiftUI__ {
			accessoryView = {
				let chevron_uiView = UIHostingController(rootView: Chevron()).view
				chevron_uiView?.sizeToFit()
				chevron_uiView?.backgroundColor = nil
				return chevron_uiView
			}()
		}
		isAccessibilityElement = true // Prevents `accessoryView` from being a separate element
	}
	
	func configure(
		with folder: Collection,
		mode: CollectionRow.Mode
	) {
		if Self.usesSwiftUI__ {
			contentConfiguration = UIHostingConfiguration {
				CollectionRow(folder: folder, mode: mode)
					.background { Color.mint.opacity(1/8) }
			}
		} else {
			titleLabel.text = { () -> String in
				// Don’t let this be `nil` or `""`. Otherwise, when we revert combining folders before `freshenLibraryItems`, the table view vertically collapses rows for deleted folders.
				guard
					let folderTitle = folder.title,
					!folderTitle.isEmpty
				else {
					return " "
				}
				return folderTitle
			}()
			contentView.layer.opacity = { () -> Float in
				if mode == .modalDisabled {
					return .oneFourth
				} else {
					return 1
				}
			}()
			
			rowContentAccessibilityLabel__ = titleLabel.text
			reflectStatus__(folder.avatarStatus__())
			
			accessibilityUserInputLabels = [folder.title].compacted()
		}
		
		switch mode {
			case .normal(let actions):
				isUserInteractionEnabled = true
				accessibilityTraits.subtract(.notEnabled)
				accessibilityCustomActions = actions
			case .modal:
				backgroundColor = .clear
				isUserInteractionEnabled = true
				accessibilityTraits.subtract(.notEnabled)
			case .modalTinted:
				backgroundColor = .tintColor.withAlphaComponent(.oneEighth)
				isUserInteractionEnabled = true
				accessibilityTraits.subtract(.notEnabled)
			case .modalDisabled:
				backgroundColor = .clear
				isUserInteractionEnabled = false
				accessibilityTraits.formUnion(.notEnabled)
		}
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		if Self.usesSwiftUI__ { return }
		
		separatorInset.left = 0
		+ contentView.frame.minX
		+ titleLabel.frame.minX
		separatorInset.right = directionalLayoutMargins.trailing
	}
}
