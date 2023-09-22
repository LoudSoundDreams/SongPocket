//
//  Collections List.swift
//  LavaRock
//
//  Created by h on 2023-09-01.
//

import SwiftUI

struct CollectionRow: View {
	enum Mode: Equatable {
		case normal([UIAccessibilityCustomAction])
		case modal
		case modalTinted
		case modalDisabled
	}
	
	let collection: Collection
	let mode: Mode
	
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
		.opacity({
			if mode == .modalDisabled {
				return .oneFourth // Close to what Files pickers use
			} else {
				return 1
			}
		}())
		// • Background color
		// • Disabling
		// • Selection style
		// • Accessibility traits
		// • Accessibility action for renaming
		.accessibilityElement(children: .combine)
		.accessibilityAddTraits(.isButton)
		.accessibilityInputLabels([collection.title].compacted()) // Exclude the now-playing status.
	}
}
