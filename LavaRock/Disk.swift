// 2024-08-30

import Foundation

struct LRCrate: Equatable {
	let title: String
	let albums: [LRAlbum]
	init(title: String, albums: [LRAlbum]) {
		self.title = title
		self.albums = albums
	}
}
struct LRAlbum: Equatable {
	let id: String
	let songs: [LRSong]
	init(id: String, songs: [LRSong]) {
		self.id = id
		self.songs = songs
	}
}
struct LRSong: Equatable {
	let id: String
	init(id: String) {
		self.id = id
	}
}

enum Disk {
	static func save(_ collections: [Collection]) { // 10,000 albums and 12,000 songs takes 40ms in 2024.
		let filer = FileManager.default
		try! filer.createDirectory(at: pDatabase, withIntermediateDirectories: true)
		
		var output: String = ""
		collections.forEach {
			output.append(contentsOf: "\($0.title ?? "")\n")
			$0.albums(sorted: true).forEach { album in
				output.append(contentsOf: "\(tAlbum)\(String(album.albumPersistentID))\n")
				album.songs(sorted: true).forEach { song in
					output.append(contentsOf: "\(ttSong)\(String(song.persistentID))\n")
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
		return Parser(input).crates()
	}
	
	fileprivate static let tAlbum = "\t"
	fileprivate static let ttSong = "\t\t"
	
	private static let pDatabase = URL.applicationSupportDirectory.appending(path: "v1/")
	private static let cCrates = "crates"
}

struct Parser {
	init(_ string: String) {
		self.lines = string.split(separator: "\n", omittingEmptySubsequences: true)
	}
	private let lines: [Substring]
	
	func crates() -> [LRCrate] {
		var result: [LRCrate] = []
		var iLine = 0
		while iLine < lines.count {
			guard isCrate(at: iLine) else {
				// Not a crate line. Skip it.
				iLine += 1
				continue
			}
			
			let crateTitle = lines[iLine]
			iLine += 1
			
			let (nextILine, albums) = albumsUntilOutdent(from: iLine)
			iLine = nextILine
			guard !albums.isEmpty else {
				// No valid albums for this crate. Skip this crate line.
				continue
			}
			result.append(
				LRCrate(title: String(crateTitle), albums: albums)
			)
		}
		return result
	}
	private func albumsUntilOutdent(from start: Int) -> (nextILine: Int, [LRAlbum]) {
		var result: [LRAlbum] = []
		var iLine = start
		while 
			iLine < lines.count,
			!isCrate(at: iLine) // Parse albums until outdent.
		{
			guard isAlbum(at: iLine) else {
				// Not an album line. Skip it.
				iLine += 1
				continue
			}
			
			let line = lines[iLine]
			let albumID = line.dropFirst(Disk.tAlbum.count)
			iLine += 1
			
			let (nextILine, songs) = songsUntilOutdent(from: iLine)
			iLine = nextILine
			guard !songs.isEmpty else {
				// No valid songs for this album. Skip this album line.
				continue
			}
			result.append(
				LRAlbum(id: String(albumID), songs: songs)
			)
		}
		return (iLine, result)
	}
	private func songsUntilOutdent(from start: Int) -> (nextILine: Int, [LRSong]) {
		var result: [LRSong] = []
		var iLine = start
		while 
			iLine < lines.count,
			!isCrate(at: iLine), !isAlbum(at: iLine) // Parse songs until outdent.
		{
			guard isSong(at: iLine) else {
				// Not a valid song line. Skip it.
				iLine += 1
				continue
			}
			
			let line = lines[iLine]
			let songID = line.dropFirst(Disk.ttSong.count)
			iLine += 1
			
			result.append(
				LRSong(id: String(songID))
			)
		}
		return (iLine, result)
	}
	
	private func isCrate(at iLine: Int) -> Bool {
		let line = lines[iLine]
		return !line.hasPrefix(Disk.tAlbum)
	}
	private func isAlbum(at iLine: Int) -> Bool {
		let line = lines[iLine]
		return line.count > Disk.tAlbum.count &&
		line.hasPrefix(Disk.tAlbum) &&
		!line.hasPrefix(Disk.ttSong)
	}
	private func isSong(at iLine: Int) -> Bool {
		let line = lines[iLine]
		return line.count > Disk.ttSong.count &&
		line.hasPrefix(Disk.ttSong)
	}
}
