//
//  MusicLibrary - Merge, Delete.swift
//  LavaRock
//
//  Created by h on 2020-09-22.
//

import CoreData

extension MusicLibrary {
	func deleteLibraryItems(
		for songs: [Song]
	) {
		songs.forEach {
			context.delete($0)
			// WARNING: Leaves gaps in the `Song` indices within each `Album`, and might leave empty `Album`s. Later, you must delete empty `Album`s and reindex the `Song`s within each `Album`.
		}
		
		context.unsafe_DeleteEmptyAlbums_WithoutReindexOrCascade()
		context.deleteEmptyCollections()
	}
}
