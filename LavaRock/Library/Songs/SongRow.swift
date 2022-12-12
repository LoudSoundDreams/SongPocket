//
//  SongRow.swift
//  LavaRock
//
//  Created by h on 2022-12-11.
//

import SwiftUI

struct SongRow: View {
	let trackDisplay: String
	let songTitleDisplay: String
	let artistDisplayOptional: String?
	
	var body: some View {
		
		HStack {
			HStack(
				alignment: .firstTextBaseline,
				spacing: .eight * (1 + 1/2) // 12
			) {
				// TO DO: Right-align across rows
				Text(trackDisplay)
					.monospacedDigit()
					.foregroundColor(.secondary)
				
				VStack(
					alignment: .leading,
					spacing: .eight * 1/2 // 4
				) {
					Text(songTitleDisplay)
					
					if let artistDisplay = artistDisplayOptional {
						Text(artistDisplay)
							.font(.caption)
							.foregroundColor(.secondary)
							.padding(.bottom, .eight * 1/4) // 2
					}
				}
				.alignmentGuide(.listRowSeparatorLeading) { textStackDimensions in
					textStackDimensions[.leading]
				}
			}
			
			Spacer()
			
			Image(systemName: "tortoise")
				.font(.body)
				.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
				.foregroundColor(.accentColor)
			
			// TO DO: Expand tappable area
			Button {
				
			} label: {
				Image(systemName: "ellipsis")
					.font(.body)
					.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
					.foregroundColor(.primary)
			}
			.alignmentGuide(.listRowSeparatorTrailing) { moreButtonDimensions in
				// TO DO: This indents the trailing inset in editing mode. Is that sensible?
				moreButtonDimensions[.trailing]
			}
		}
		.padding(.top, .eight * -1/4) // -2
		
	}
}
