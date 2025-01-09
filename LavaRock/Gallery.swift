// 2025-01-09

import SwiftUI

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

