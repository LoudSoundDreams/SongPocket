// 2024-08-30

import Foundation
import os

enum Disk {
	static func write(_ collections: [Collection]) { // 10,000 albums and 12,000 songs takes 40ms in 2024.
		let signposter = OSSignposter()
		let _save = signposter.beginInterval("save")
		defer { signposter.endInterval("save", _save) }
		
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
		let cCrates = "crates"
		let options: Data.WritingOptions = [.atomic, .completeFileProtection]
		try! data.write(to: URL.applicationSupportDirectory.appending(path: cCrates), options: options)
	}
	
	static func read() -> [Collection] {
		return []
	}
}
