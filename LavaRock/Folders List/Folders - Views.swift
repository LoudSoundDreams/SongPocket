//
//  Folders - Views.swift
//  LavaRock
//
//  Created by h on 2020-11-06.
//

import UIKit
import SwiftUI

// TO DO: Delete
final class CreateFolderCell: UITableViewCell {
	@IBOutlet private var newFolderLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		newFolderLabel.text = LRString.newFolder
		newFolderLabel.textColor = .tintColor
		
		accessibilityTraits.formUnion(.button)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		separatorInset.right = directionalLayoutMargins.trailing
	}
}

enum FolderRowMode {
	case normal([UIAccessibilityCustomAction])
	case modal
	case modalTinted
	case modalDisabled
}
struct FolderRow: View {
	let folder: Collection
	let mode: FolderRowMode
	
	var body: some View {
		HStack {
			Text(folder.title ?? " ")
			Spacer()
			AvatarImage(libraryItem: folder)
				.offset(y: -0.5)
				.accessibilitySortPriority(10)
		}
		.opacity({
			if case FolderRowMode.modalDisabled = mode {
				return .oneFourth
			} else {
				return 1
			}
		}())
		.accessibilityElement(children: .combine)
		.accessibilityAddTraits(.isButton)
		.accessibilityInputLabels(
			// Exclude the now-playing marker.
			[
				folder.title, // Can be `nil`
			].compacted()
		)
	}
}
final class FolderCell: UITableViewCell {
	static let usesSwiftUI__ = 10 == 1
	
	@IBOutlet var spacerSpeakerImageView: UIImageView!
	@IBOutlet var speakerImageView: UIImageView!
	var rowContentAccessibilityLabel__: String? = nil
	
	@IBOutlet private var titleLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		backgroundColor = .clear
	}
	
	func configure(
		with folder: Collection,
		mode: FolderRowMode
	) {
		if Self.usesSwiftUI__ {
			contentConfiguration = UIHostingConfiguration {
				FolderRow(
					folder: folder,
					mode: mode)
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
				if case FolderRowMode.modalDisabled = mode {
					return .oneFourth
				} else {
					return 1
				}
			}()
			
			rowContentAccessibilityLabel__ = titleLabel.text
			indicateAvatarStatus__(
				folder.avatarStatus__()
			)
			
			// Exclude the now-playing marker.
			accessibilityUserInputLabels = [
				folder.title, // Can be `nil`
			].compacted()
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
