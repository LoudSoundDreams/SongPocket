// 2024-04-04

import SwiftUI

struct TheBar: View {
	var body: some View {
		Button("hop", systemImage: "hare") {
		}
	}
}

struct ButtonPanel: View {
	var body: some View {
		HStack(spacing: .zero) {
			VStack(spacing: .zero) {
				Spacer()
				
				ZStack {
					Rectangle()
						.foregroundStyle(Color.yellow.opacity(.one_half))
						.aspectRatio(1, contentMode: .fit)
					Image(systemName: "chevron.forward")
				}
				.onTapGesture {
					Print(Date())
				}
				.opacity(is_touching ? .one_half : 1)
				.animation({
					if is_touching {
						return nil
					} else { return .linear_quick() }
				}(), value: is_touching)
				.onLongPressGesture(minimumDuration: .zero) {
				} onPressingChanged: {
					is_touching = $0
				}
			}
			
			VStack(spacing: .zero) {
				Button {} label: {
					ZStack {
						Rectangle()
							.foregroundStyle(Color.green.opacity(.one_half))
							.aspectRatio(1, contentMode: .fill)
						Image(systemName: "checkmark")
					}
				}
				Button {} label: {
					ZStack {
						Rectangle()
							.foregroundStyle(Color.blue.opacity(.one_half))
						Image(systemName: "arrowtriangle.up")
					}
				}
				Button {} label: {
					ZStack {
						Rectangle()
							.foregroundStyle(Color.purple.opacity(.one_half))
						Image(systemName: "arrowtriangle.down")
					}
				}
			}
		}
	}
	@State private var is_touching = false
}
