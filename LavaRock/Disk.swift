// 2024-08-30

import Foundation
import os

enum Disk {
	static func save_crates(_ crates: [LRCrate]) { // 10,000 albums and 12,000 songs takes 40ms in 2024.
		let _save = signposter.beginInterval("save")
		defer { signposter.endInterval("save", _save) }
		
		try! FileManager.default.createDirectory(at: folder_v1, withIntermediateDirectories: true)
		
		let _serialize = signposter.beginInterval("serialize")
		var stream: String = ""
		crates.forEach {
			stream.append(contentsOf: "\($0.title)\(newline)")
			$0.lrAlbums.forEach { album in
				stream.append(contentsOf: "\(tab)\(album.uAlbum)\(newline)")
				album.lrSongs.forEach { song in
					stream.append(contentsOf: "\(tab_tab)\(song.uSong)\(newline)")
				}
			}
		}
		signposter.endInterval("serialize", _serialize)
		
		let data = stream.data(using: encoding_utf8, allowLossyConversion: false)!
		try! data.write(
			to: file_crates,
			options: [.atomic, .completeFileProtection])
	}
	
	static func load_crates() -> [LRCrate] {
		guard let data = try? Data(contentsOf: file_crates) else {
			// Maybe the file doesn’t exist.
			return []
		}
		
		guard let input: String = String(data: data, encoding: encoding_utf8) else {
			Print("Couldn’t decode crates file.")
			return []
		}
		return Parser(input).parse_crates()
	}
	
	fileprivate static let encoding_utf8: String.Encoding = .utf8
	fileprivate static let newline = "\n"
	fileprivate static let tab = "\t"
	fileprivate static let tab_tab = "\t\t"
	
	private static let folder_v1: URL = .applicationSupportDirectory.appending(path: "v1/")
	private static let file_crates: URL = folder_v1.appending(path: "crates")
	private static let signposter = OSSignposter(subsystem: "persistence", category: "disk")
}

struct Parser {
	init(_ string: String) {
		self.lines = string.split(separator: Disk.newline, omittingEmptySubsequences: false)
	}
	private let lines: [Substring]
	
	func parse_crates() -> [LRCrate] {
		let _crates = signposter.beginInterval("crates")
		defer { signposter.endInterval("crates", _crates) }
		
		var result: [LRCrate] = []
		var i_line = 0
		while i_line < lines.count {
			let content = lines[i_line]
			
			guard is_crate(at: i_line) else {
				// Not a crate line. Skip it.
				i_line += 1
				continue
			}
			
			i_line += 1
			let (next_i_line, albums) = albums_until_outdent(from: i_line)
			
			i_line = next_i_line
			guard !albums.isEmpty else {
				// No valid albums for this crate. Skip this crate line.
				continue
			}
			let parsed_crate = LRCrate(title: String(content))
			parsed_crate.lrAlbums = albums
			result.append(parsed_crate)
			let _ = content
		}
		return result
	}
	private func albums_until_outdent(
		from start: Int
	) -> (
		next_i_line: Int,
		[LRAlbum]
	) {
		let _albums = signposter.beginInterval("albums")
		defer { signposter.endInterval("albums", _albums) }
		
		var result: [LRAlbum] = []
		var i_line = start
		while
			i_line < lines.count,
			!is_crate(at: i_line) // Parse albums until outdent.
		{
			let line = lines[i_line]
			let content = line.dropFirst(Disk.tab.count)
			let uAlbum: UAlbum? = UAlbum(String(content))
			
			guard
				is_album(at: i_line),
				let uAlbum
			else {
				// Not an album line. Skip it.
				i_line += 1
				continue
			}
			
			i_line += 1
			let (next_i_line, songs) = songs_until_outdent(
				from: i_line,
				uAlbum: uAlbum)
			
			i_line = next_i_line
			guard !songs.isEmpty else {
				// No valid songs for this album. Skip this album line.
				continue
			}
			let parsed_album = LRAlbum(uAlbum: uAlbum, songs: songs)
			result.append(parsed_album)
		}
		return (i_line, result)
	}
	private func songs_until_outdent(
		from start: Int,
		uAlbum: UAlbum
	) -> (
		next_i_line: Int,
		[LRSong]
	) {
		let _songs = signposter.beginInterval("songs")
		defer { signposter.endInterval("songs", _songs) }
		
		var result: [LRSong] = []
		var i_line = start
		while
			i_line < lines.count,
			!is_crate(at: i_line), !is_album(at: i_line) // Parse songs until outdent.
		{
			let line = lines[i_line]
			let content = line.dropFirst(Disk.tab_tab.count)
			let uSong: USong? = USong(String(content))
			
			guard
				is_song(at: i_line),
				let uSong
			else {
				// Not a valid song line. Skip it.
				i_line += 1
				continue
			}
			
			i_line += 1
			let parsed_song = LRSong(uSong: uSong)
			result.append(parsed_song)
		}
		return (i_line, result)
	}
	
	private func is_crate(at iLine: Int) -> Bool {
		let line = lines[iLine]
		return !line.hasPrefix(Disk.tab)
	}
	private func is_album(at iLine: Int) -> Bool {
		let line = lines[iLine]
		return line.count > Disk.tab.count &&
		line.hasPrefix(Disk.tab) &&
		!line.hasPrefix(Disk.tab_tab)
	}
	private func is_song(at iLine: Int) -> Bool {
		let line = lines[iLine]
		return line.count > Disk.tab_tab.count &&
		line.hasPrefix(Disk.tab_tab)
	}
	
	private let signposter = OSSignposter(subsystem: "persistence", category: "parser")
}
