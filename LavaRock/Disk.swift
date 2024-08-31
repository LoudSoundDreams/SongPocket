// 2024-08-30

import Foundation

enum Disk {
	static func save(_ collections: [Collection]) { // 10,000 albums and 12,000 songs takes 40ms in 2024.
		let pDatabase = URL.applicationSupportDirectory.appending(path: "v1/")
		let filer = FileManager.default
		try! filer.createDirectory(at: pDatabase, withIntermediateDirectories: true)
		
		var output: String = ""
		collections.forEach {
			output.append(contentsOf: "\($0.title ?? "")\n")
			$0.albums(sorted: true).forEach { album in
				output.append(contentsOf: "\t\(String(album.albumPersistentID))\n")
				album.songs(sorted: true).forEach { song in
					output.append(contentsOf: "\t\t\(String(song.persistentID))\n")
				}
			}
		}
		let data = Data(output.utf8)
		try! data.write(to: pDatabase.appending(path: "crates"), options: [.atomic, .completeFileProtection])
	}
	
	static func load() -> [Collection] {
		return []
	}
}
