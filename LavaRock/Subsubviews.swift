// 2024-11-22

import SwiftUI

struct Separator: View {
	var body: some View {
		Rectangle()
			.foregroundStyle(Color(white: .one_fourth))
			.frame(maxWidth: .infinity, maxHeight: 1 * points_per_pixel)
	}
	@Environment(\.pixelLength) private var points_per_pixel
}

struct RectSelected: View {
	var body: some View {
		Rectangle()
			.strokeBorder(lineWidth: .eight)
			.foregroundStyle(.tint.opacity(.one_half))
	}
}
struct RectUnselected: View {
	var body: some View {
		Rectangle()
			.strokeBorder(lineWidth: .eight)
			.foregroundStyle(Material.ultraThin)
	}
}

struct IconSelected: View {
	var body: some View {
		Image(systemName: "ellipsis.circle.fill")
			.font_body_dynamicType_up_to_xxxLarge()
			.accessibilityRemoveTraits(.isSelected) // This code looks wrong, but as of iOS 18.2 developer beta 3, VoiceOver automatically adds “Selected” because of the SF Symbol.
	}
}
struct IconUnselected: View {
	var body: some View {
		Image(systemName: "ellipsis.circle.fill")
			.font_body_dynamicType_up_to_xxxLarge()
			.symbolRenderingMode(.hierarchical)
			.accessibilityLabel(InterfaceText.Select)
			.accessibilityRemoveTraits(.isSelected)
	}
}
