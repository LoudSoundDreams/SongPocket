// 2024-08-30

import Foundation
import MusicKit

final class LRCrate {
	let title: String
	let albums: [LRAlbum]
	init(title: String, albums: [LRAlbum]) {
		self.title = title
		self.albums = albums
	}
}
final class LRAlbum {
	let id: String
	let songs: [LRSong]
	init(id: String, songs: [LRSong]) {
		self.id = id
		self.songs = songs
	}
}
final class LRSong {
	let id: String
	init(id: String) {
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
		return Parser(input).crates()
	}
}

struct Parser {
	init(_ string: String) {
		let string = """
	1
		2
	3
5
7
	11
	13
		17
		
	
		19
		23
	29
31
37
	41
		43
"""
		self.lines = string.split(separator: "\n", omittingEmptySubsequences: true)
	}
	private let lines: [Substring]
	
	func crates() -> [LRCrate] {
		var result: [LRCrate] = []
		var iLine = 0
		while iLine < lines.count {
			let line = lines[iLine]
			print(line, "crates?", iLine)
			
			iLine += 1
			guard isCollection(line) else {
				// Not a crate line. Skip it.
				print("not a crate line")
				continue
			}
			print("crate line")
			let (newILine, albums) = albumsUntilOutdent(from: iLine)
			iLine = newILine
			guard !albums.isEmpty else {
				// No valid album lines in block below. Skip this crate line.
				print("no album lines")
				continue
			}
			result.append(
				LRCrate(title: String(line), albums: albums)
			)
		}
		return result
	}
	private func albumsUntilOutdent(from start: Int) -> (newILine: Int, [LRAlbum]) {
		var result: [LRAlbum] = []
		var iLine = start
		while iLine < lines.count {
			let line = lines[iLine]
			print(line, "albums?", iLine)
			
			guard !isCollection(line) else {
				// Outdent. Stop parsing for albums.
				break
			}
			
			iLine += 1
			guard let albumLine = isAlbum(line) else {
				// Not an album line. Skip it.
				print("\tnot an album line")
				continue
			}
			print("\talbum line")
			let (newILine, songs) = songsUntilOutdent(from: iLine)
			iLine = newILine
			guard !songs.isEmpty else {
				// No valid song lines in block below. Skip this album line.
				print("\tno song lines")
				continue
			}
			result.append(
				LRAlbum(id: String(albumLine), songs: songs)
			)
		}
		print("\tend albums")
		return (iLine, result)
	}
	private func songsUntilOutdent(from start: Int) -> (newILine: Int, [LRSong]) {
		var result: [LRSong] = []
		var iLine = start
		while iLine < lines.count {
			let line = lines[iLine]
			print(line, "songs?", iLine)
			
			guard !isCollection(line), isAlbum(line) == nil else {
				// Outdent. Stop parsing for songs.
				break
			}
			
			iLine += 1
			guard let songLine = isSong(line) else {
				// Not a valid song line. Skip it.
				print("\t\tnot a song line")
				continue
			}
			print("\t\tsong line")
			result.append(
				LRSong(id: String(songLine))
			)
		}
		print("\t\tend songs")
		return (iLine, result)
	}
	
	private func isCollection(_ line: Substring) -> Bool {
		guard let char = line.first, char != "\t" else { return false }
		return true
	}
	private func isAlbum(_ line: Substring) -> Substring? {
		let prefix = "\t"
		guard line.hasPrefix(prefix) else { return nil }
		let content = line.dropFirst(prefix.count)
		guard let char = content.first, char != "\t" else { return nil }
		return content
	}
	private func isSong(_ line: Substring) -> Substring? {
		let prefix = "\t\t"
		guard line.hasPrefix(prefix) else { return nil }
		let content = line.dropFirst(prefix.count)
		guard let char = content.first, char != "\t" else { return nil }
		return content
	}
}
