// 2024-12-28

import SwiftUI

@MainActor @Observable final class TheBarState {
	@ObservationIgnored static let shared = TheBarState()
	var mode: TheBarMode = .zero
	private init() {}
}
enum TheBarMode {
	case zero, one, two
}

struct TheBar: View {
	private let bar_state: TheBarState = .shared
	var body: some View {
		ZStack {
			switch bar_state.mode {
				case .zero:
					Button("crawl", systemImage: "tortoise") {
					}
				case .one:
					Button("hop", systemImage: "hare") {
					}
				case .two:
					Button("finish", systemImage: "arrow.up.backward.and.arrow.down.forward.circle.fill") {
					}
			}
		}.animation(.default, value: bar_state.mode)
	}
}
