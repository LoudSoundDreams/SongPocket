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
						if visiblePosition != nil && visiblePosition! > 0 {
							visiblePosition! -= 1
						}
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
						if visiblePosition != nil && visiblePosition! < albums.count - 1 {
							visiblePosition! += 1
						}
					}
				} label: { Image(systemName: "arrow.forward") }
					.disabled({ guard let visiblePosition else { return false }; return visiblePosition >= albums.count - 1 }())
				Spacer()
				Button {
					withAnimation {
						albums.append(
							FakeAlbum(
								position: albums.count,
								title: {
									let alphabet = "abcdefghijklmnopqrstuvwxyz"
									let letters: [String] = alphabet.map { String($0) }
									return letters.randomElement()!
								}()))
					}
				} label: { Image(systemName: "plus.circle") }
			} }
		}
	}
}

struct AlbumList: View {
	@State private var albums: [FakeAlbum] = FakeAlbum.demoArray {
		didSet {
			albums.enumerated().forEach { offset, album in
				print(album.title, terminator: "")
			}
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
	var position: Int
	let title: String
	static let demoArray: [FakeAlbum] = {
		var result: [FakeAlbum] = []
		let titles = "abcd"
		titles.enumerated().forEach { offset, letter in
			result.append(FakeAlbum(position: offset, title: String(letter)))
		}
		return result
	}()
	
	let circleColor = Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1))
	let squareColor = Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1))
}
extension FakeAlbum: Identifiable {
	var id: Int { position }
}
