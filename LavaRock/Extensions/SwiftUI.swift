//
//  SwiftUI.swift
//  LavaRock
//
//  Created by h on 2023-08-09.
//

import SwiftUI

struct Chevron: View {
	var body: some View {
		// Similar to what Apple Music uses for search results
		Image(systemName: "chevron.forward")
			.foregroundStyle(.secondary)
			.imageScale(.small)
	}
}

extension View {
	func fontTitle2_bold() -> some View {
		// As of iOS 16.6, Apple Music uses this for “Recently Added”.
		font(.title2).bold()
	}
	func __fontHeadline() -> some View {
		// As of iOS 16.6, Apple Music uses this for the current song title on the now-playing screen.
		font(.headline)
	}
	func fontCaption2_bold() -> some View {
		/*
		 As of iOS 16.6, Apple Music uses this for…
		 • Genre, release year, and “Lossless” on album details views
		 • Radio show titles
		 */
		font(.caption2).bold()
	}
	func fontFootnote() -> some View {
		// As of iOS 16.6, Apple Music uses this for artist names on song rows.
		font(.footnote)
	}
	
	func fontBody_dynamicTypeSizeUpToXxxLarge() -> some View {
		return self
			.font(.body)
			.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
	}
	
	func alignmentGuide_separatorLeading() -> some View {
		alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
			viewDimensions[.leading]
		}
	}
	func alignmentGuide_separatorTrailing() -> some View {
		alignmentGuide(.listRowSeparatorTrailing) { viewDimensions in
			viewDimensions[.trailing]
		}
	}
}
