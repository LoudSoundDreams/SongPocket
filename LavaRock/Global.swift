// 2025-01-29

import Observation
import Foundation

@MainActor @Observable final class Global {
	private init() {}
	
	var showcase: Exhibit? // Consider multiple `Exhibit`s.
	var librarian_is_merging = false { didSet { // Prevent users from modifying items while the app is modifying them.
		if !librarian_is_merging {
			NotificationCenter.default.post(name: .librarian_merged, object: nil)
		}
	}}
}
extension Global {
	@ObservationIgnored static let shared = Global()
	func go_to_artwork() {
		guard
			let uSong = LCD.shared.uSong_current,
			let album = Librarian.album_containing_uSong[uSong]?.referencee
		else { return }
		showcase?.focus = .spotlight(album.uAlbum)
	}
}
