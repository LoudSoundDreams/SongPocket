// 2021-04-09

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
