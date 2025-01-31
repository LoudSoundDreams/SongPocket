// 2025-01-29

import Observation
import Foundation

enum WorkingOn {
	static let toolbar = 10 == 10
}

@MainActor @Observable final class Global {
	private init() {}
	
	@ObservationIgnored var showcase: Exhibit?
	var showcase_is_spotlighting = false
	@ObservationIgnored weak var gallery: ExhibitTVC?
	
	var librarian_is_merging = false { didSet { // Prevent users from modifying items while the app is modifying them.
		if !librarian_is_merging {
			NotificationCenter.default.post(name: .librarian_merged, object: nil)
		}
	}}
}
extension Global {
	@ObservationIgnored static let shared = Global()
}
