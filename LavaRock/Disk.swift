// 2024-08-30

import Foundation

enum Disk {
	static func write(_ collections: [Collection]) {
		let cCrates = "crates/"
		let pNewCrates = URL.temporaryDirectory.appending(path: cCrates)
		let filer = FileManager.default
		let options: Data.WritingOptions = [.atomic, .completeFileProtection]
		collections.forEach {
			$0.albums(sorted: false).forEach { album in
				let pAlbum = pNewCrates.appending(path: "0/albums/\(album.index)/")
				try! filer.createDirectory(at: pAlbum, withIntermediateDirectories: true)
				
				let dAlbumID = Data(String(album.albumPersistentID).utf8)
				try! dAlbumID.write(to: pAlbum.appending(path: "id"), options: options)
				
				let sSongs: String = {
					var result = ""
					album.songs(sorted: true).forEach {
						result.append("\($0.persistentID)\n")
					}
					return result
				}()
				let dSongs = Data(sSongs.utf8)
				try! dSongs.write(to: pAlbum.appending(path: "songs"), options: options)
			}
		}
		let pCrates = URL.applicationSupportDirectory.appending(path: "v1/\(cCrates)")
		try! filer.createDirectory(at: pCrates, withIntermediateDirectories: true)
		let _ = try! filer.replaceItemAt(pCrates, withItemAt: pNewCrates)
	}
	
	static func read() -> [Collection] {
		return []
	}
}
