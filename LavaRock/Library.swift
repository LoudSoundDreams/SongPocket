// 2021-04-09

import CoreData

enum Library {
	static func renumber(_ items: [NSManagedObject]) { // Replace with `LibraryItem`
		items.enumerated().forEach { (currentIndex, item) in
			item.setValue(Int64(currentIndex), forKey: "index")
		}
	}
}

protocol LibraryItem: NSManagedObject {
	@MainActor func containsPlayhead() -> Bool
}
extension Collection: LibraryItem {
	@MainActor final func containsPlayhead() -> Bool {
#if targetEnvironment(simulator)
		return objectID == Sim_Global.currentSong?.container?.container?.objectID
#else
		guard let currentSong = managedObjectContext?.songInPlayer() else { return false }
		return objectID == currentSong.container?.container?.objectID
#endif
	}
}
extension Album: LibraryItem {
	@MainActor final func containsPlayhead() -> Bool {
#if targetEnvironment(simulator)
		return objectID == Sim_Global.currentSong?.container?.objectID
#else
		guard let songInPlayer = managedObjectContext?.songInPlayer() else { return false }
		return objectID == songInPlayer.container?.objectID
#endif
	}
}
extension Song: LibraryItem {
	@MainActor final func containsPlayhead() -> Bool {
#if targetEnvironment(simulator)
		return objectID == Sim_Global.currentSong?.objectID
#else
		guard let songInPlayer = managedObjectContext?.songInPlayer() else { return false }
		return objectID == songInPlayer.objectID
#endif
	}
}
