// 2024-08-30

import Foundation
import MusicKit

final class LRCrate {
	let index: Int64
	let title: String
	init(index: Int64, title: String) {
		self.index = index
		self.title = title
	}
}
final class LRAlbum {
	let index: Int64
	init(index: Int64) {
		self.index = index
	}
}
final class LRSong {
	let index: Int64
	let id: String
	init(index: Int64, id: String) {
		self.index = index
		self.id = id
	}
}

enum Disk {
	private static let pDatabase = URL.applicationSupportDirectory.appending(path: "v1/")
	private static let cCrates = "crates"
	
	static func save(_ collections: [Collection]) { // 10,000 albums and 12,000 songs takes 40ms in 2024.
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
		try! data.write(to: pDatabase.appending(path: cCrates), options: [.atomic, .completeFileProtection])
	}
	
	static func load() -> [LRCrate] {
		guard let data = try? Data(contentsOf: pDatabase.appending(path: cCrates)) else {
			// Maybe the file doesn’t exist.
			return []
		}
		
		guard let input: String = String(data: data, encoding: .utf8) else {
			print("Couldn’t decode crates file.")
			return []
		}
		let lines: [Substring] = input.split(separator: "\n", omittingEmptySubsequences: true)
		
		let result: [LRCrate] = []
		var currentSongs: [LRSong] = []
		lines.forEach { line in
			var tabs: Int = 0
			let content: Substring = line.drop {
				tabs += 1
				return $0 == "\t"
			}
			
			switch tabs {
				case 0:
					break
				case 1:
					break
				case 2:
					currentSongs.append(
						LRSong(
							index: Int64(currentSongs.count),
							id: String(content))
					)
				default: break
			}
		}
		return result
	}
}
