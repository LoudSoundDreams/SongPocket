// 2024-04-04

import SwiftUI

struct BubbleBar: View {
	var body: some View {
		HStack(alignment: .bottom) {
			Menu {
			} label: {
				Image(systemName: "play.circle.fill")
					.symbolRenderingMode(.hierarchical)
			}
			Menu {
			} label: {
				Image(systemName: "ellipsis.circle.fill")
					.symbolRenderingMode(.hierarchical)
			}
		}
		.font(.largeTitle)
		.dynamicType_default_to_plus_3()
		.padding(.eight)
		.background(Material.bar, in: .capsule)
	}
}

private extension View {
	func reacting(_ active: Bool) -> some View {
		return self
			.overlay {
				Color.black.opacity(active ? .one_fourth : .zero)
			}
			.animation(active ? nil : .linear_quick(), value: active)
	}
}
