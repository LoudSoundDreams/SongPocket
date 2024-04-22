// 2021-04-09

import CoreData

enum Library {
	static func renumber(_ items: [NSManagedObject]) {
		items.enumerated().forEach { (currentIndex, item) in
			item.setValue(Int64(currentIndex), forKey: "index")
		}
	}
}

extension Song {
	@MainActor final func containsPlayhead() -> Bool {
#if targetEnvironment(simulator)
		return objectID == Sim_Global.currentSong?.objectID
#else
		guard let songInPlayer = managedObjectContext?.songInPlayer() else { return false }
		return objectID == songInPlayer.objectID
#endif
	}
}
