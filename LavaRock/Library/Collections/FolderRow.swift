//
//  FolderRow.swift
//  LavaRock
//
//  Created by h on 2023-03-18.
//

import SwiftUI
import UIKit

enum FolderRowMode {
	case normal([UIAccessibilityCustomAction])
	case modal
	case modalTinted
	case modalDisabled
}

struct FolderRow: View {
	let collection: Collection
	
	var body: some View {
		HStack {
			Text(collection.title ?? "")
			
			Spacer()
			
			AvatarImage(
				libraryItem: collection
			)
			.accessibilitySortPriority(10)
		}
		.accessibilityElement(children: .combine)
		.accessibilityAddTraits(.isButton)
		.accessibilityInputLabels(
			[
				collection.title,
			].compacted()
		)
	}
}
