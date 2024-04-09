// 2024-04-04

import SwiftUI

struct AlbumShelf: View {
	@State private var albums: [FakeAlbum] = FakeAlbum.demoArray {
		didSet {
		}
	}
	@State private var visiblePosition: Int? = 2
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
					}
				}
				.scrollTargetLayout()
			}
			.scrollTargetBehavior(.viewAligned(limitBehavior: .never))
			.scrollPosition(id: $visiblePosition)
			.toolbar(.visible, for: .bottomBar)
			.toolbarBackground(.visible, for: .bottomBar)
			.toolbar { ToolbarItemGroup(placement: .bottomBar) {
				Button {
				} label: { Image(systemName: "minus.circle") }
				Spacer()
				Button {
					withAnimation {
						if let pos = visiblePosition, pos > 0 { visiblePosition = pos - 1 }
					}
				} label: { Image(systemName: "arrow.backward") }
					.disabled({ guard let visiblePosition else { return false }; return visiblePosition <= 0 }())
				Spacer()
				ZStack {
					Text(String(albums.count - 1)).hidden()
					Text({ guard let visiblePosition else { return "" }; return String(visiblePosition) }())
						.animation(.none)
				}
				Spacer()
				Button {
					withAnimation {
						if let pos = visiblePosition, pos < albums.count - 1 { visiblePosition = pos + 1 }
					}
				} label: { Image(systemName: "arrow.forward") }
					.disabled({ guard let visiblePosition else { return false }; return visiblePosition >= albums.count - 1 }())
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
		didSet {
		}
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

struct FakeAlbum: Hashable {
	static let demoArray: [Self] = {
		return (0...3).map { Self(position: $0, title: .randomLowercaseLetter()) }
	}()
	var position: Int
	let title: String
	let circleColor = Color.random()
	let squareColor = Color.random()
}
extension FakeAlbum: Identifiable {
	var id: Int { position }
}

extension String {
	static func randomLowercaseLetter() -> Self {
		let character = "abcdefghijklmnopqrstuvwxyz".randomElement()!
		return String(character)
	}
}
