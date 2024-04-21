// 2023-08-09

import SwiftUI

extension Color {
	static func random() -> Self {
		return Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1))
	}
}

extension View {
	// As of iOS 16.6, Apple Music uses this for “Recently Added”.
	func fontTitle2Bold() -> some View { font(.title2).bold() }
	
	// As of iOS 16.6, Apple Music uses this for the current song title on the now-playing screen.
	func fontHeadline_() -> some View { font(.headline) }
	
	/*
	 As of iOS 16.6, Apple Music uses this for…
	 • Genre, release year, and “Lossless” on album details views
	 • Radio show titles
	 */
	func fontCaption2Bold() -> some View { font(.caption2).bold() }
	
	// As of iOS 16.6, Apple Music uses this for artist names on song rows.
	func fontFootnote() -> some View { font(.footnote) }
	
	func fontBody_dynamicTypeSizeUpToXxxLarge() -> some View {
		return self
			.font(.body)
			.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
	}
	
	func alignmentGuide_separatorLeading() -> some View {
		alignmentGuide(.listRowSeparatorLeading) { viewDim in viewDim[.leading] }
	}
	func alignmentGuide_separatorTrailing() -> some View {
		alignmentGuide(.listRowSeparatorTrailing) { viewDim in viewDim[.trailing] }
	}
}
