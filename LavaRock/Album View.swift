// 2024-04-04

import SwiftUI

struct AlbumShelf: View {
	@State private var albums: [FakeAlbum] = FakeAlbum.demoArray {
		didSet { FakeAlbum.renumber(albums) }
	}
	@State private var visibleIndex: Int? = 2
	var body: some View {
		ScrollViewReader { proxy in
			ScrollView(.horizontal) {
				LazyHStack {
					ForEach(albums) { album in
						ZStack {
							Rectangle().foregroundStyle(album.squareColor)
							Circle().foregroundStyle(album.circleColor)
							Text(album.title)
						}
						.aspectRatio(1, contentMode: .fit)
						.containerRelativeFrame(.horizontal)
						.id(album.position)
					}
				}
				.scrollTargetLayout()
			}
			.scrollTargetBehavior(.viewAligned(limitBehavior: .never))
			.scrollPosition(id: $visibleIndex)
			.toolbar(.visible, for: .bottomBar)
			.toolbarBackground(.visible, for: .bottomBar)
			.toolbar { ToolbarItemGroup(placement: .bottomBar) {
				Button {
				} label: { Image(systemName: "minus.circle") }
				Spacer()
				Button {
					withAnimation {
						if let pos = visibleIndex, pos > 0 { visibleIndex = pos - 1 }
					}
				} label: { Image(systemName: "arrow.backward") }
					.disabled({ guard let visibleIndex else { return false }; return visibleIndex <= 0 }())
				Spacer()
				ZStack {
					Text(String(albums.count - 1)).hidden()
					Text({ guard let visibleIndex else { return "" }; return String(visibleIndex) }())
						.animation(.none)
				}
				Spacer()
				Button {
					withAnimation {
						if let pos = visibleIndex, pos < albums.count - 1 { visibleIndex = pos + 1 }
					}
				} label: { Image(systemName: "arrow.forward") }
					.disabled({ guard let visibleIndex else { return false }; return visibleIndex >= albums.count - 1 }())
				Spacer()
				Button {
					albums.append(FakeAlbum(position: albums.count, title: .randomLowercaseLetter()))
				} label: { Image(systemName: "plus.circle") }
			} }
		}
	}
}

struct AlbumList: View {
	@State private var albums: [FakeAlbum] = FakeAlbum.demoArray {
		didSet { FakeAlbum.renumber(albums) }
	}
	@State private var selectedAlbums: Set<FakeAlbum> = []
	var body: some View {
		List(selection: $selectedAlbums) {
			ForEach($albums, editActions: .move) { $album in
				Text(album.title)
			}
			.onMove { from, to in
				albums.move(fromOffsets: from, toOffset: to)
			}
		}
	}
}

// If this were a struct, `[FakeAlbum].didSet` would loop infinitely when you set one of `FakeAlbum`’s properties.
final class FakeAlbum: Identifiable {
	static let demoArray: [FakeAlbum] = {
		return (0...3).map { FakeAlbum(position: $0, title: .randomLowercaseLetter()) }
	}()
	static func renumber(_ albums: [FakeAlbum]) {
		albums.indices.forEach { albums[$0].position = $0 }
	}
	
	var position: Int
	let title: String
	let circleColor = Color.random()
	let squareColor = Color.random()
	
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

extension String {
	static func randomLowercaseLetter() -> Self {
		let character = "abcdefghijklmnopqrstuvwxyz".randomElement()!
		return String(character)
	}
}
