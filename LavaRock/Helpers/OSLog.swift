//
//  OSLog.swift
//  LavaRock
//
//  Created by h on 2021-12-22.
//

import OSLog

extension OSLog {
	static let collection = OSLog(
		subsystem: "1. Collection",
		category: .pointsOfInterest)
	static let album = OSLog(
		subsystem: "2. Album",
		category: .pointsOfInterest)
	static let song = OSLog(
		subsystem: "3. Song",
		category: .pointsOfInterest)
	
	private static let musicLibraryManagerSubsystem = "4. MusicLibraryManager"
	static let merge = OSLog(
		subsystem: musicLibraryManagerSubsystem,
		category: "A. Main")
	static let update = OSLog(
		subsystem: musicLibraryManagerSubsystem,
		category: "B. Update")
	static let create = OSLog(
		subsystem: musicLibraryManagerSubsystem,
		category: "C. Create")
	static let delete = OSLog(
		subsystem: musicLibraryManagerSubsystem,
		category: "D. Delete")
	static let cleanup = OSLog(
		subsystem: musicLibraryManagerSubsystem,
		category: "E. Cleanup")
	
	static let albumsView = OSLog(
		subsystem: "6. Albums View",
		category: "category")
	static let songsView = OSLog(
		subsystem: "7. Albums View",
		category: "category")
}
