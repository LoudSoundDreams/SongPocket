//
//  Collections - Views.swift
//  LavaRock
//
//  Created by h on 2020-11-06.
//

import SwiftUI
import UIKit

struct CollectionRow: View {
	let collection: Collection
	let dimmed: Bool
	
	var body: some View {
		HStack {
			Text(collection.title ?? " ")
			Spacer()
			HStack(alignment: .firstTextBaseline) {
				AvatarImage(libraryItem: collection).accessibilitySortPriority(10)
				Chevron()
			}
		}
		.alignmentGuide_separatorTrailing()
		.opacity(
			dimmed
			? .oneFourth // Close to what Files pickers use
			: 1
		)
		.accessibilityElement(children: .combine)
		.accessibilityAddTraits(.isButton)
		.accessibilityInputLabels([collection.title].compacted()) // Exclude the now-playing status.
	}
}

final class CollectionCell: UITableViewCell {
	static let usesSwiftUI__ = 10 == 1
	
	@IBOutlet var spacerSpeakerImageView: UIImageView!
	@IBOutlet var speakerImageView: UIImageView!
	var rowContentAccessibilityLabel__: String? = nil
	
	@IBOutlet private var titleLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		backgroundColor = .clear
		
		editingAccessoryType = .detailButton
		if !Self.usesSwiftUI__ {
			accessoryView = {
				let chevron_uiView = UIHostingController(rootView: Chevron()).view
				chevron_uiView?.sizeToFit()
				chevron_uiView?.backgroundColor = nil
				return chevron_uiView
			}()
			isAccessibilityElement = true // Prevents `accessoryView` from being a separate element
		}
	}
	
	func configure(
		with collection: Collection,
		dimmed: Bool
	) {
		if Self.usesSwiftUI__ {
			contentConfiguration = UIHostingConfiguration {
				CollectionRow(collection: collection, dimmed: dimmed)
			}
		} else {
			titleLabel.text = { () -> String in
				// Don’t let this be `nil` or `""`. Otherwise, when we revert combining collections before `freshenLibraryItems`, the table view vertically collapses rows for deleted collections.
				guard
					let collectionTitle = collection.title,
					!collectionTitle.isEmpty
				else {
					return " "
				}
				return collectionTitle
			}()
			contentView.layer.opacity = dimmed ? .oneFourth : 1
			
			rowContentAccessibilityLabel__ = titleLabel.text
			reflectStatus__(collection.avatarStatus__())
			
			accessibilityUserInputLabels = [collection.title].compacted()
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
