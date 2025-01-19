// 2024-04-04

import SwiftUI

struct TheBar: View {
	var body: some View {
		Button("hop", systemImage: "hare") {
		}
	}
}

extension View {
	func on_touching_changed(
		respond: @escaping (_ is_touching: Bool) -> Void
	) -> some View {
		onLongPressGesture(minimumDuration: .zero) {
		} onPressingChanged: {
			respond($0)
		}
	}
	
	func opacity_reacting(_ active: Bool) -> some View {
		return self
			.opacity(active ? .one_half : 1)
			.animation(active ? nil : .linear_quick(), value: active)
	}
}

struct ButtonPanel: View {
	var body: some View {
		HStack(spacing: .zero) {
			ZStack {
				Color.yellow.opacity(.one_half)
				Image(systemName: "chevron.forward")
			}
			.onTapGesture {
				Print(Date())
			}
			.opacity_reacting(is_touching_detail)
			.on_touching_changed { is_touching_detail = $0 }
			
			VStack(spacing: .zero) {
				Button {} label: {
					ZStack {
						Color.green.opacity(.one_half)
						Image(systemName: "checkmark")
					}
					.opacity_reacting(is_touching_select)
					.on_touching_changed { is_touching_select = $0 }
				}
				HStack(spacing: .zero) {
					Button {} label: {
						ZStack {
							Color.blue.opacity(.one_half)
							Image(systemName: "arrowtriangle.up")
						}
					}
					Button {} label: {
						ZStack {
							Color.purple.opacity(.one_half)
							Image(systemName: "arrowtriangle.down")
						}
					}
				}
			}
		}
	}
	@State private var is_touching_detail = false
	@State private var is_touching_select = false
}
