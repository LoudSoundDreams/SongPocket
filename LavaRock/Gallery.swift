// 2025-01-09

import SwiftUI

@MainActor @Observable final class GalleryState {
	private(set) var exhibits: [Exhibit] = [.all_albums, .all_albums]
	var __selection: Selection = .view(nil) { didSet {
		NotificationCenter.default.post(name: Self.selection_changed, object: nil)
	}}
	private init() {}
}
extension GalleryState {
	@ObservationIgnored static let shared = GalleryState()
	enum Selection {
		case view(USong?)
		case mode_albums(Set<UAlbum>)
		case mode_songs(Set<USong>)
	}
	@ObservationIgnored static let selection_changed = Notification.Name("LR_GallerySelectionChanged")
}

enum Exhibit {
	case all_albums
	case one_album(UAlbum)
}

struct Gallery: View {
	private let gallery_state: GalleryState = .shared
	var body: some View {
		TabView {
			ForEach(gallery_state.exhibits.indices, id: \.self) { i_exhibit in
				let exhibit = gallery_state.exhibits[i_exhibit]
				RepAlbumTable(exhibit: exhibit)
					.ignoresSafeArea() // Fills the `TabView`.
			}
		}
		.tabViewStyle(.page(indexDisplayMode: .never))
		.background { Color(white: .one_eighth) } // As of iOS 18.3 developer beta 2, this influences layout; we need a non-clear color here, or `TabView` janks the scroll position while you move pages. Otherwise, I’d prefer no background here.
		.persistentSystemOverlays(.hidden)
	}
}

private struct RepAlbumTable {
	let exhibit: Exhibit
}
extension RepAlbumTable: UIViewControllerRepresentable {
	func makeUIViewController(context: Context) -> AlbumTable {
		return AlbumTable.init_please(exhibit)
	}
	func updateUIViewController(_ vc: AlbumTable, context: Context) {}
}

