//
//  OSLog.swift
//  LavaRock
//
//  Created by h on 2021-12-22.
//

import OSLog

extension OSLog {
	static let folder = OSLog(
		subsystem: "1. Folder",
		category: .pointsOfInterest)
	static let album = OSLog(
		subsystem: "2. Album",
		category: .pointsOfInterest)
	static let song = OSLog(
		subsystem: "3. Song",
		category: .pointsOfInterest)
	
	private static let music_library = "4. MusicLibrary"
	static let merge = OSLog(
		subsystem: music_library,
		category: "A. Main")
	static let update = OSLog(
		subsystem: music_library,
		category: "B. Update")
	static let create = OSLog(
		subsystem: music_library,
		category: "C. Create")
	static let delete = OSLog(
		subsystem: music_library,
		category: "D. Delete")
	static let cleanup = OSLog(
		subsystem: music_library,
		category: "E. Cleanup")
	
	static let albumsView = OSLog(
		subsystem: "6. Albums View",
		category: "_")
	static let songsView = OSLog(
		subsystem: "7. Songs View",
		category: "_")
}
