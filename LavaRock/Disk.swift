// 2024-08-30

import Foundation
import os

enum Disk {
	private static let signposter = OSSignposter(subsystem: "disk", category: .pointsOfInterest)
	
	fileprivate static let line_break = "\n"
	fileprivate static let prefix_song = "_"
	
	static func save_albums(_ albums: [LRAlbum]) {
		let _save = signposter.beginInterval("save")
		defer { signposter.endInterval("save", _save) }
		
		// Serialize
		var stream: String = ""
		albums.forEach { album in
			stream.append(
				contentsOf: "\(album.uAlbum)\(line_break)"
			)
			album.uSongs.forEach { uSong in
				stream.append(
					contentsOf: "\(prefix_song)\(uSong)\(line_break)"
				)
			}
		}
		
		// Write
		let data = stream.data(using: encoding_utf8, allowLossyConversion: false)!
		try! FileManager.default.createDirectory(at: folder_v1, withIntermediateDirectories: true)
		try! data.write(to: file_albums)
	}
	static func load_albums() -> [LRAlbum] {
		let _load = signposter.beginInterval("load")
		defer { signposter.endInterval("load", _load) }
		
		// Read
		guard let data = try? Data(contentsOf: file_albums)
		else {
			// Maybe the file doesn’t exist.
			return []
		}
		
		// Parse
		guard let stream: String = String(data: data, encoding: encoding_utf8)
		else {
			Print("Couldn’t decode albums file.")
			return []
		}
		return Parser(stream).parse_albums()
	}
	
	private static let folder_v1: URL = .applicationSupportDirectory.appending(path: "v1/")
	private static let file_albums: URL = folder_v1.appending(path: "albums")
	private static let encoding_utf8: String.Encoding = .utf8
}

struct Parser {
	init(_ stream: String) {
		self.lines = stream.split(
			separator: Disk.line_break,
			omittingEmptySubsequences: false)
	}
	private let lines: [Substring]
	
	func parse_albums() -> [LRAlbum] {
		var result: [LRAlbum] = []
		var i_line = 0
		while i_line < lines.count {
			let line = lines[i_line]
			let content = String(line)
			let uAlbum: UAlbum? = UAlbum(content)
			
			guard
				is_album(at: i_line),
				let uAlbum
			else {
				// Not a valid album line.
				i_line += 1
				continue
			}
			
			i_line += 1
			let (next_i_line, uSongs) = uSongs_until_outdent(from: i_line)
			
			i_line = next_i_line
			guard !uSongs.isEmpty else {
				// No valid songs for this album. Disallow empty albums.
				continue
			}
			result.append(
				LRAlbum(uAlbum: uAlbum, uSongs: uSongs)
			)
		}
		return result
	}
	private func uSongs_until_outdent(from start: Int)
	-> (
		next_i_line: Int,
		[USong]
	) {
		var result: [USong] = []
		var i_line = start
		while
			i_line < lines.count,
			!is_album(at: i_line) // Stop if we should start a new album.
		{
			let line = lines[i_line]
			let content: String = String(line.dropFirst(Disk.prefix_song.count))
			let uSong: USong? = USong(content)
			
			guard
				is_song(at: i_line),
				let uSong
			else {
				// Not a valid song line.
				i_line += 1
				continue
			}
			
			i_line += 1
			result.append(uSong)
		}
		return (i_line, result)
	}
	
	private func is_album(at i_line: Int) -> Bool {
		let line = lines[i_line]
		return !line.hasPrefix(Disk.prefix_song)
	}
	private func is_song(at i_line: Int) -> Bool {
		let line = lines[i_line]
		return line.hasPrefix(Disk.prefix_song)
	}
}
