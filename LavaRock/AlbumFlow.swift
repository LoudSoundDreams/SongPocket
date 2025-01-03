// 2024-04-04

import SwiftUI

struct AlbumFlow: View { // Experimental.
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
			
			.toolbar { ToolbarItemGroup(placement: .bottomBar) {
				Button {
				} label: { Image(systemName: "minus.circle") }
				Spacer()
				ZStack {
					Text("999").hidden()
					Text("001")
				}.monospacedDigit()
				Spacer()
				Button {
					uuids.append(UUID())
				} label: { Image(systemName: "plus.circle") }
			}}
		}
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

struct FakeAlbumCover: View {
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
		.animation(.linear(duration: .one_eighth), value: is_reordering)
		.onLongPressGesture(minimumDuration: .one_eighth) {
			is_reordering = true
		} onPressingChanged: { is_pressing in
			if !is_pressing { is_reordering = false }
		}
	}
	@State private var is_reordering = false
}

private extension String {
	static func debug_random() -> Self {
		let character = "abcdefghijklmnopqrstuvwxyz".randomElement()!
		return String(character)
	}
}
