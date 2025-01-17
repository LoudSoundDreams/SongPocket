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
		Border().foregroundStyle(Material.ultraThin)
	}
}
struct BorderSelected: View {
	var body: some View {
		Border().foregroundStyle(.tint.opacity(.one_half))
	}
}
private struct Border: View {
	var body: some View {
		Rectangle().strokeBorder(lineWidth: .eight)
	}
}

struct IconUnselected: View {
	var body: some View {
		Ellipsis()
			.symbolRenderingMode(.hierarchical)
			.accessibilityLabel(InterfaceText.Select)
			.accessibilityRemoveTraits(.isSelected)
	}
}
struct IconSelected: View {
	var body: some View {
		Ellipsis()
			.accessibilityRemoveTraits(.isSelected) // This code looks wrong, but as of iOS 18.2 developer beta 3, VoiceOver automatically adds “Selected” because of the SF Symbol.
	}
}
private struct Ellipsis: View {
	var body: some View {
		Image(systemName: "ellipsis.circle.fill")
			.font_body_dynamicType_up_to_xxxLarge()
	}
}

struct PlaceholderMusicNote: View {
	var body: some View {
		Image(systemName: "music.note")
			.foregroundStyle(Color(white: .one_half))
			.font(.title)
	}
}

extension UIImage {
	static var reverse: Self { sf("arrow.uturn.up") }
	static var shuffle: Self { sf("shuffle") }
	static var move_up: Self { sf("arrow.up.circle.fill") }
	static var move_down: Self { sf("arrow.down.circle.fill") }
	static var to_top: Self { sf("arrow.up.to.line") }
	static var to_bottom: Self { sf("arrow.down.to.line") }
	static func random_die() -> Self {
		return sf({
			switch Int.random(in: 1...6) {
				case 1: return "die.face.1"
				case 2: return "die.face.2"
				case 3: return "die.face.3"
				case 4: return "die.face.4"
				case 5: return "die.face.5"
				default: return "die.face.6"
			}
		}())
	}
	
	private static func sf(_ symbol_name: String) -> Self {
		return Self(systemName: symbol_name)!
	}
}
