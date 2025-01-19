// 2024-04-04

import SwiftUI

struct ButtonPanel: View {
	var body: some View {
		HStack(spacing: .zero) {
			ZStack {
				Rectangle().foregroundStyle(Material.ultraThin)
				Image(systemName: "chevron.forward")
			}
			.onTapGesture {
				Print(Date(), "expand")
			}
			.reacting(is_touching_detail)
			.touching($is_touching_detail)
			
			VStack(spacing: .zero) {
				ZStack {
					Rectangle().foregroundStyle(Material.ultraThin)
					Image(systemName: "checkmark")
				}
				.onTapGesture {
					Print(Date(), "select")
				}
				.reacting(is_touching_select)
				.touching($is_touching_select)
				
				HStack(spacing: .zero) {
					ZStack {
						Rectangle().foregroundStyle(Material.ultraThin)
						Image(systemName: "arrowtriangle.up")
					}
					.onTapGesture {
						Print(Date(), "up")
					}
					.reacting(is_touching_up)
					.touching($is_touching_up)
					
					ZStack {
						Rectangle().foregroundStyle(Material.ultraThin)
						Image(systemName: "arrowtriangle.down")
					}
					.onTapGesture {
						Print(Date(), "down")
					}
					.reacting(is_touching_down)
					.touching($is_touching_down)
				}
			}
		}
	}
	@State private var is_touching_detail = false
	@State private var is_touching_select = false
	@State private var is_touching_up = false
	@State private var is_touching_down = false
}

extension View {
	func reacting(_ active: Bool) -> some View {
		return self
			.opacity(active ? .one_half : 1)
			.animation(active ? nil : .linear_quick(), value: active)
	}
	
	func touching(_ variable: Binding<Bool>) -> some View {
		onLongPressGesture(minimumDuration: .zero) {
		} onPressingChanged: {
			variable.wrappedValue = $0
		}
	}
}

struct TheBar: View {
	var body: some View {
		Button("hop", systemImage: "hare") {
		}
	}
}
