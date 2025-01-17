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
				.opacity(opacity_tap)
				.onLongPressGesture(minimumDuration: .zero, perform: {
					Print(Date())
				}, onPressingChanged: { pressing in
					if pressing {
						opacity_tap = .one_half
					} else {
						withAnimation {
							opacity_tap = 1
						}
					}
				})
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
	@State private var opacity_tap: Double = 1
}
