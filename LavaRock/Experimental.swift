// 2024-04-04

import SwiftUI

struct AlbumShelf: View {
	@State private var albums: [FakeAlbum] = FakeAlbum.demoArray() { didSet {
		FakeAlbum.renumber(albums)
	}}
	@State private var i_visible: Int? = 2
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
			.toolbar(.visible, for: .bottomBar)
			.toolbarBackground(.visible, for: .bottomBar)
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
					albums.append(FakeAlbum(position: albums.count, title: .random_letter()))
				} label: { Image(systemName: "plus.circle") }
			}}
		}
	}
}

struct AlbumList: View {
	@State private var albums: [FakeAlbum] = FakeAlbum.demoArray() { didSet {
		FakeAlbum.renumber(albums)
	}}
	@State private var selected: Set<FakeAlbum> = []
	var body: some View {
		List(selection: $selected) {
			ForEach($albums, editActions: .move) { $album in
				FakeAlbumCover(album: album)
					.listRowInsets(EdgeInsets(top: .zero, leading: .zero, bottom: .zero, trailing: .zero))
			}.onMove { from, to in
				albums.move(fromOffsets: from, toOffset: to)
			}
		}.listStyle(.plain)
	}
}

// MARK: Subviews

struct FakeAlbumCover: View {
	let album: FakeAlbum
	var body: some View {
		ZStack {
			Rectangle().foregroundStyle(album.color_square)
			Circle().foregroundStyle(album.color_circle)
			Text(album.title)
		}.aspectRatio(1, contentMode: .fit)
	}
}

// MARK: - Model

// If this were a struct, `[FakeAlbum].didSet` would loop infinitely when you set one of `FakeAlbum`’s properties.
final class FakeAlbum: Identifiable {
	static func demoArray() -> [FakeAlbum] {
		return (0...3).map {
			FakeAlbum(position: $0, title: .random_letter())
		}
	}
	static func renumber(_ albums: [FakeAlbum]) {
		albums.indices.forEach { albums[$0].position = $0 }
	}
	
	var position: Int
	let title: String
	let color_circle = Color.random_translucent()
	let color_square = Color.random_translucent()
	
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

// MARK: - Helpers

private extension String {
	static func random_letter() -> Self {
		let character = "abcdefghijklmnopqrstuvwxyz".randomElement()!
		return String(character)
	}
}
