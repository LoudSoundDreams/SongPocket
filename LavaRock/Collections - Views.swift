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
		HStack(alignment: .firstTextBaseline) {
			ZStack(alignment: .leading) {
				Chevron().hidden()
				AvatarImage(
					libraryItem: collection,
					state: SystemMusicPlayer.sharedIfAuthorized!.state,
					queue: SystemMusicPlayer.sharedIfAuthorized!.queue
				).accessibilitySortPriority(10)
			}
			
			Text({ () -> String in 
				// Don’t let this be `nil` or `""`. Otherwise, when we revert combining collections before `freshenLibraryItems`, the table view vertically collapses rows for deleted collections.
				guard let title, !title.isEmpty else {
					return " "
				}
				return title
			}())
			.multilineTextAlignment(.center)
			.frame(maxWidth: .infinity)
			.padding(.bottom, .eight * 1/4)
			
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
		// ! Accessibility action
		// ! Accessibility “selected” state
	}
}
