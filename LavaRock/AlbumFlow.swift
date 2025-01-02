// 2024-04-04

import SwiftUI

struct AlbumFlow: View { // Experimental.
	var body: some View {
		ScrollViewReader { proxy in
			ScrollView(.horizontal) {
				LazyHStack { ForEach(albums) { album in
					FakeAlbumCover(album: album)
						.containerRelativeFrame(.horizontal)
						.id(album.position)
				}}.scrollTargetLayout()
			}
			.scrollTargetBehavior(.viewAligned(limitBehavior: .never))
			.scrollPosition(id: $i_visible)
			.toolbar { ToolbarItemGroup(placement: .bottomBar) {
				Button {
				} label: { Image(systemName: "minus.circle") }
				Spacer()
				Button {
					withAnimation {
						if let pos = i_visible, pos > 0 { i_visible = pos - 1 }
					}
				} label: { Image(systemName: "arrow.backward") }
					.disabled({ guard let i_visible else { return false }; return i_visible <= 0 }())
					.animation(.none, value: i_visible) // Without this, if you enable the button by tapping “next”, the icon fades in.
				Spacer()
				ZStack {
					Text(String(albums.count - 1)).hidden()
					Text({ guard let i_visible else { return "" }; return String(i_visible) }())
						.animation(.none)
				}
				Spacer()
				Button {
					withAnimation {
						if let pos = i_visible, pos < albums.count - 1 { i_visible = pos + 1 }
					}
				} label: { Image(systemName: "arrow.forward") }
					.disabled({ guard let i_visible else { return false }; return i_visible >= albums.count - 1 }())
					.animation(.none, value: i_visible)
				Spacer()
				Button {
					albums.append(FakeAlbum(position: albums.count, title: .debug_random()))
				} label: { Image(systemName: "plus.circle") }
			}}
		}
	}
	@State private var albums: [FakeAlbum] = FakeAlbum.demoArray() { didSet {
		FakeAlbum.renumber(albums)
	}}
	@State private var i_visible: Int? = 2
}

struct FakeAlbumCover: View {
	let album: FakeAlbum
	var body: some View {
		ZStack {
			Rectangle().foregroundStyle(Color.debug_random())
			Circle().foregroundStyle(Color.debug_random())
			Text(album.title)
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

// If this were a struct, `[FakeAlbum].didSet` would loop infinitely when you set one of `FakeAlbum`’s properties.
final class FakeAlbum: Identifiable {
	static func demoArray() -> [FakeAlbum] {
		return (0...3).map {
			FakeAlbum(position: $0, title: .debug_random())
		}
	}
	static func renumber(_ albums: [FakeAlbum]) {
		albums.indices.forEach { i_album in
			albums[i_album].position = i_album
		}
	}
	
	var position: Int
	let title: String
	init(position: Int, title: String) {
		self.position = position
		self.title = title
	}
	
	// `Identifiable`
	let id = UUID()
}
extension FakeAlbum: Equatable {
	static func == (lhs: FakeAlbum, rhs: FakeAlbum) -> Bool {
		return lhs.position == rhs.position
	}
}
extension FakeAlbum: Hashable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(position)
	}
}

private extension String {
	static func debug_random() -> Self {
		let character = "abcdefghijklmnopqrstuvwxyz".randomElement()!
		return String(character)
	}
}
