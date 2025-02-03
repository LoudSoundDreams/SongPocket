// 2025-01-29

import Observation
import Foundation

@MainActor @Observable final class Global {
	private init() {}
	
	var showcase: Exhibit?
	var librarian_is_merging = false { didSet { // Prevent users from modifying items while the app is modifying them.
		if !librarian_is_merging {
			NotificationCenter.default.post(name: .librarian_merged, object: nil)
		}
	}}
	
	@ObservationIgnored weak var gallery: ExhibitTVC?
}
extension Global {
	@ObservationIgnored static let shared = Global()
}
