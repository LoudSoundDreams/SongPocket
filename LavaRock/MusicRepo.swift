// 2020-08-10

import CoreData
import MediaPlayer

final class MusicRepo: ObservableObject {
	static let shared = MusicRepo()
	private init() {}
	@Published private(set) var signal_mergedChanges = false // Value doesn’t actually matter
	func watchMPLibrary() {
		library?.endGeneratingLibraryChangeNotifications()
		library = MPMediaLibrary.default()
		library?.beginGeneratingLibraryChangeNotifications()
		NotificationCenter.default.addObserverOnce(self, selector: #selector(mergeChanges), name: .MPMediaLibraryDidChange, object: library)
		mergeChanges()
	}
	
	private var library: MPMediaLibrary? = nil
	let context = Database.viewContext
	@objc private func mergeChanges() {
#if targetEnvironment(simulator)
		context.performAndWait {
			mergeChangesToMatch(freshInAnyOrder: Array(Sim_SongInfo.everyInfo.values))
		}
#else
		if let freshMediaItems = MPMediaQuery.songs().items {
			context.performAndWait {
				mergeChangesToMatch(freshInAnyOrder: freshMediaItems)
			}
		}
#endif
	}
	private func mergeChangesToMatch(freshInAnyOrder: [SongInfo]) {
		let defaults = UserDefaults.standard
		let keyHasSaved = LRDefaultsKey.hasSavedDatabase.rawValue
		
		let hasSaved = defaults.bool(forKey: keyHasSaved) // Returns `false` if there’s no saved value
		let isFirstImport = !hasSaved
		
		// Find out which existing `Song`s we need to delete, and which we need to potentially update.
		// Meanwhile, isolate the `SongInfo`s that we don’t have `Song`s for. We’ll create new `Song`s for them.
		let toUpdate: [(existing: Song, fresh: SongInfo)]
		let toDelete: [Song]
		let toCreate: [SongInfo]
		do {
			var updates: [(Song, SongInfo)] = []
			var deletes: [Song] = []
			
			var freshInfos: [SongID: SongInfo] = {
				let tuples = freshInAnyOrder.map { info in (info.songID, info) }
				return Dictionary(uniqueKeysWithValues: tuples)
			}()
			let existingSongs: [Song] = context.objectsFetched(for: Song.fetchRequest()) // Not sorted
			existingSongs.forEach { existingSong in
				let songID = existingSong.persistentID
				if let freshInfo = freshInfos[songID] {
					// We have an existing `Song` for this `SongInfo`. We might need to update the `Song`.
					updates.append((existingSong, freshInfo)) // We’ll sort these later.
					
					freshInfos[songID] = nil
				} else {
					// This `Song` no longer corresponds to any `SongInfo` in the library. We’ll delete it.
					deletes.append(existingSong)
				}
			}
			// `freshInfos` now holds the `SongInfo`s that we don’t have `Song`s for.
			
			toUpdate = updates
			toDelete = deletes
			toCreate = freshInfos.map { $0.value } // We’ll sort these later.
		}
		
		// Update before creating and deleting, so that we can easily put new `Song`s above modified `Song`s.
		// This also deletes all but one `Album` with any given `albumPersistentID`.
		// This might create `Album`s, but not `Collection`s or `Song`s.
		// This might delete `Album`s, but not `Collection`s or `Song`s.
		// This also might leave behind empty `Album`s. We don’t delete those here, so that if the user also added other `Song`s to those `Album`s, we can keep those `Album`s in the same place, instead of re-adding them to the top.
		updateLibraryItems(existingAndFresh: toUpdate)
		
		// Create before deleting, because deleting also cleans up empty `Album`s and `Collection`s, which we shouldn’t do yet (see above).
		// This might create new `Album`s, and if it does, it might create new `Collection`s.
		let existingAlbums = Album.allFetched(sorted: false, context: context) // Order doesn’t matter, because we identify `Album`s by their `albumPersistentID`.
		let existingCollections = Collection.allFetched(sorted: true, context: context) // Order matters, because we’ll try to add new `Album`s to the first `Collection` with a matching title.
		createLibraryItems(
			for: toCreate,
			existingAlbums: existingAlbums,
			existingCollections: existingCollections,
			isFirstImport: isFirstImport)
		cleanUpLibraryItems(
			songsToDelete: toDelete,
			allInfos: freshInAnyOrder,
			isFirstImport: isFirstImport)
		
		context.tryToSave()
		
		defaults.set(true, forKey: keyHasSaved)
		
		DispatchQueue.main.async {
			NotificationCenter.default.post(name: .LRMergedChanges, object: nil)
			self.signal_mergedChanges.toggle()
		}
	}
}
