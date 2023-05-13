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
	let folder: Collection
	let mode: FolderRowMode
	
	var body: some View {
		HStack {
			Text(folder.title ?? "")
			
			Spacer()
			
			AvatarImage(
				libraryItem: folder)
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
