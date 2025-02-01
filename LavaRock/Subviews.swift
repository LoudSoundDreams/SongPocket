// 2024-11-22

import SwiftUI
import UIKit

struct Separator: View {
	var body: some View {
		Rectangle()
			.foregroundStyle(Color(white: .one_fourth))
			.frame(maxWidth: .infinity, maxHeight: 1 * points_per_pixel)
	}
	@Environment(\.pixelLength) private var points_per_pixel
}

struct BorderUnselected: View {
	var body: some View {
		Border().foregroundStyle(Material.regular)
	}
}
struct BorderSelected: View {
	var body: some View {
		Border().foregroundStyle(Color.accentColor.opacity(.one_half))
	}
}
struct Border: View {
	var body: some View {
		Rectangle().strokeBorder(lineWidth: .eight)
	}
}

struct EllipsisUnselected: View {
	var body: some View {
		Image(systemName: SF.ellipsis)
			.symbolRenderingMode(.hierarchical)
			.accessibilityLabel(InterfaceText.Select)
	}
}
struct EllipsisSelected: View {
	var body: some View {
		Image(systemName: SF.ellipsis)
			.accessibilityLabel(InterfaceText.Select)
			.accessibilityAddTraits(.isSelected)
	}
}

struct Placeholder: View {
	var body: some View {
		Image(systemName: SF.music_note)
			.foregroundStyle(Color(white: .one_half))
			.font(.title)
	}
}
