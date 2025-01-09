// 2024-04-04

import SwiftUI

@MainActor @Observable final class TheBarState {
	var mode: TheBarMode = .zero
	private init() {}
}
extension TheBarState {
	@ObservationIgnored static let shared = TheBarState()
}
enum TheBarMode {
	case zero, one, two
}

struct TheBar: View {
	private let bar_state: TheBarState = .shared
	var body: some View {
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
	}
}

struct Gallery: View {
	var body: some View {
		TabView(selection: $rando_spotlighted) {
			ForEach(randos, id: \.self) { rando in
				RepAlbumTable()
					.ignoresSafeArea() // Fills the `TabView`.
			}
		}
		.tabViewStyle(.page(indexDisplayMode: .never))
		.background { Color(red: .one_half, green: .zero, blue: .one_half) } // Should never appear, but influences layout.
		.persistentSystemOverlays(.hidden)
	}
	@State private var randos: [UUID] = {
		var result: [UUID] = []
		result.append(Self.rando_default)
		(1 ... 9).forEach { _ in
			result.append(UUID())
		}
		return result
	}()
	@State private var rando_spotlighted: UUID = Self.rando_default // As of iOS 18.3 developer beta 1, this breaks if we use type `UUID?`; `TabView` always selects the first tab.
	private static let rando_default = UUID()
	
	private func remove(_ rando: UUID) {
		guard let i_rando = randos.firstIndex(of: rando) else { return }
		let new_rando_spotlighted: UUID? = {
			guard randos.count >= 2 else { return nil }
			let i_next_rando: Int = min(i_rando + 1, randos.count - 1)
			let result = randos[i_next_rando]
			return result
		}()
		let _ = withAnimation { // Unreliable; the first time after any swipe, SwiftUI crossfades the new tab into place rather than pushing it.
			randos.remove(at: i_rando)
			if let new_rando_spotlighted {
				rando_spotlighted = new_rando_spotlighted
			}
		}
	}
}

private struct RepAlbumTable: UIViewControllerRepresentable {
	typealias VCType = AlbumTable
	func makeUIViewController(context: Context) -> AlbumTable {
		return AlbumTable.init_from_storyboard()
	}
	func updateUIViewController(_ vc: AlbumTable, context: Context) {}
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
		.animation(.linear(duration: .one_eighth), value: is_reordering)
		.onLongPressGesture(minimumDuration: .one_fourth) {
			withAnimation {
				is_reordering = true
			}
		} onPressingChanged: { is_pressing in
			if !is_pressing {
				withAnimation {
					is_reordering = false
				}
			}
		}
	}
	@State private var is_reordering = false
}
