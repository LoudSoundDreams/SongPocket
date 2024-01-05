//
//  Collections - Views.swift
//  LavaRock
//
//  Created by h on 2020-11-06.
//

import SwiftUI
import MusicKit
import UIKit

struct CollectionRow: View {
	let title: String?
	let collection: Collection
	let dimmed: Bool
	
	var body: some View {
		HStack {
			ZStack(alignment: .leading) {
				AvatarImage(
					libraryItem: collection,
					state: SystemMusicPlayer.sharedIfAuthorized!.state,
					queue: SystemMusicPlayer.sharedIfAuthorized!.queue
				).accessibilitySortPriority(10)
				Chevron().hidden()
			}
			Text({ () -> String in // Don’t let this be `nil` or `""`. Otherwise, when we revert combining collections before `freshenLibraryItems`, the table view vertically collapses rows for deleted collections.
				guard let title, !title.isEmpty else {
					return " "
				}
				return title
			}())
			.multilineTextAlignment(.center)
			.frame(maxWidth: .infinity)
			ZStack(alignment: .trailing) {
				AvatarPlayingImage().hidden()
				Chevron()
			}
		}
		.alignmentGuide_separatorLeading()
		.alignmentGuide_separatorTrailing()
		.accessibilityElement(children: .combine)
		.accessibilityAddTraits(.isButton)
		.opacity(
			dimmed
			? .oneFourth // Close to what Files pickers use
			: 1
		)
		.disabled(dimmed)
		.accessibilityInputLabels([title].compacted()) // Exclude the now-playing status.
	}
}

final class CollectionCell: UITableViewCell {
	static let usesSwiftUI = 10 == 10
	
	@IBOutlet var spacerSpeakerImageView: UIImageView!
	@IBOutlet var speakerImageView: UIImageView!
	var rowContentAccessibilityLabel__: String? = nil
	
	@IBOutlet private var titleLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		if Self.usesSwiftUI { return }
		
		accessoryView = {
			let chevron_uiView = UIHostingController(rootView: Chevron()).view
			chevron_uiView?.sizeToFit()
			chevron_uiView?.backgroundColor = nil
			return chevron_uiView
		}()
		isAccessibilityElement = true // Prevents `accessoryView` from being a separate element
	}
	
	func configure(
		with collection: Collection,
		dimmed: Bool
	) {
		if Self.usesSwiftUI {
			contentConfiguration = UIHostingConfiguration {
				CollectionRow(title: collection.title, collection: collection, dimmed: dimmed)
			}
		} else {
			titleLabel.text = { () -> String in
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
			reflectAvatarStatus(collection.avatarStatus__())
			
			accessibilityUserInputLabels = [collection.title].compacted()
		}
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		if Self.usesSwiftUI { return }
		
		separatorInset.left = 0
		+ contentView.frame.minX
		+ titleLabel.frame.minX
		separatorInset.right = directionalLayoutMargins.trailing
	}
}
