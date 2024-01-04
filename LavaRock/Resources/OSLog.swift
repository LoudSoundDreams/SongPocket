//
//  OSLog.swift
//  LavaRock
//
//  Created by h on 2021-12-22.
//

import OSLog

extension OSLog {
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
	static let cleanup = OSLog(
		subsystem: music_library,
		category: "E. Cleanup")
}
