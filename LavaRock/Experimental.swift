// 2024-04-04

import SwiftUI

struct TheBar: View {
	private let global: GlobalState = .shared
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

struct Flow: View {
	var body: some View {
		ScrollViewReader { proxy in
			ScrollView(.horizontal) {
				LazyHStack { ForEach(uuids, id: \.self) { uuid in
					FakeAlbumCover(uuid: uuid)
						.containerRelativeFrame(.horizontal)
						.id(uuid)
				}}.scrollTargetLayout()
			}
			.scrollTargetBehavior(.viewAligned(limitBehavior: .never))
			.scrollPosition(id: $uuid_target)
		}.toolbar { ToolbarItemGroup(placement: .bottomBar) {
			Button {
				guard
					let uuid_target,
					let i_uuid_target = uuids.firstIndex(of: uuid_target)
				else { return }
				let _ = withAnimation {
					uuids.remove(at: i_uuid_target)
				}
			} label: { Image(systemName: "minus.circle") }
			Spacer()
			ZStack {
				Text("99999").hidden()
				Text({ () -> String in
					guard let uuid_target else { return "nil" }
					let string = "\(uuid_target)"
					return String(string.prefix(4))
				}())
			}.monospacedDigit()
			Spacer()
			Button {
				uuids.append(UUID())
			} label: { Image(systemName: "plus.circle") }
		}}
	}
	@State private var uuids: [UUID] = {
		var result: [UUID] = []
		result.append(Self.uuid_default)
		(1 ... 10).forEach { _ in
			result.append(UUID())
		}
		return result
	}()
	@State private var uuid_target: UUID? = Self.uuid_default
	private static let uuid_default = UUID()
}

// MARK: Subviews

private struct FakeAlbumCover: View {
	let uuid: UUID
	
	var body: some View {
		ZStack {
			Rectangle().foregroundStyle(Color.debug_random())
			Circle().foregroundStyle(Color.debug_random())
			Text("\(uuid)")
		}
		.aspectRatio(1, contentMode: .fit)
		.scaleEffect(is_reordering ? (1 + 1 / CGFloat.eight) : 1)
		.opacity(is_reordering ? Double.one_half : 1)
		.animation(.linear_quick(), value: is_reordering)
		.onLongPressGesture(minimumDuration: .one_fourth) {
			withAnimation {
				is_reordering = true
			}
		} onPressingChanged: { pressing in
			if !pressing {
				withAnimation {
					is_reordering = false
				}
			}
		}
	}
	@State private var is_reordering = false
}
