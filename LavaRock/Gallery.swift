// 2025-01-09

import SwiftUI

@MainActor @Observable final class GalleryState {
	private(set) var exhibits: [Exhibit] = {
		if WorkingOn.gallery {
			return Librarian.the_albums.map { .one_album($0.uAlbum) }
		} else {
			return [.all_albums]
		}
	}()
	var focus: Focus = .cover { didSet {
		NotificationCenter.default.post(name: Self.focus_changed, object: nil)
	}}
	var __selection: Selection = .view(nil) { didSet {
		NotificationCenter.default.post(name: Self.selection_changed, object: nil)
	}}
	private init() {}
}
extension GalleryState {
	@ObservationIgnored static let shared = GalleryState()
	
	enum Focus {
		case cover
		case tracklist(UAlbum) // `UAlbum` is only necessary when `!WorkingOn.gallery`.
	}
	@ObservationIgnored static let focus_changed = Notification.Name("LR_GalleryFocus")
	
	enum Selection {
		case view(USong?)
		case mode_albums(Set<UAlbum>)
		case mode_songs(Set<USong>)
	}
	@ObservationIgnored static let selection_changed = Notification.Name("LR_GallerySelection")
}
extension GalleryState.Focus: Equatable {}

enum Exhibit {
	case all_albums
	case one_album(UAlbum)
}
extension Exhibit: Hashable {}

struct Gallery: View {
	private let gallery_state: GalleryState = .shared
	var body: some View {
		TabView {
			ForEach(gallery_state.exhibits, id: \.self) { exhibit in
				RepAlbumTable(exhibit: exhibit)
					.ignoresSafeArea() // Fills the `TabView`.
			}
		}
		.tabViewStyle(.page(indexDisplayMode: .never))
		.background { Color(white: .one_eighth) } // As of iOS 18.3 developer beta 2, this influences layout; we need a non-clear color here, or `TabView` janks the scroll position while you move pages. Otherwise, I’d prefer no background here.
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

