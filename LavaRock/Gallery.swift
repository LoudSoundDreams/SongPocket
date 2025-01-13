// 2025-01-09

import SwiftUI

@MainActor @Observable final class GalleryState {
	var focus: Focus = .cover { didSet {
		NotificationCenter.default.post(name: Self.changed_focus, object: nil)
	}}
	var __selection: Selection = .view(nil) { didSet {
		NotificationCenter.default.post(name: Self.changed_selection, object: nil)
	}}
	private init() {}
}
extension GalleryState {
	@ObservationIgnored static let shared = GalleryState()
	
	enum Focus {
		case cover
		case tracklist(UAlbum)
	}
	@ObservationIgnored static let changed_focus = Notification.Name("LR_GalleryFocus")
	
	enum Selection {
		case view(USong?)
		case mode_albums(Set<UAlbum>)
		case mode_songs(Set<USong>)
	}
	@ObservationIgnored static let changed_selection = Notification.Name("LR_GallerySelection")
}
extension GalleryState.Focus: Equatable {}
