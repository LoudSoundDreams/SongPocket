// 2024-08-30

import Foundation
import os

enum Disk {
	static func save_crates(_ crates: [LRCrate]) { // 10,000 albums and 12,000 songs takes 40ms in 2024.
		let _save = signposter.beginInterval("save")
		signposter.endInterval("save", _save)
		
		let filer = FileManager.default
		try! filer.createDirectory(at: path_folder, withIntermediateDirectories: true)
		
		let _serialize = signposter.beginInterval("serialize")
		var output: String = ""
		crates.forEach {
			output.append(contentsOf: "\($0.title)\n")
			$0.lrAlbums.forEach { album in
				output.append(contentsOf: "\(tab)\(album.mpid)\n")
				album.lrSongs.forEach { song in
					output.append(contentsOf: "\(tab_tab)\(song.mpid)\n")
				}
			}
		}
		signposter.endInterval("serialize", _serialize)
		let data = Data(output.utf8)
		try! data.write(to: path_folder.appending(path: step_crates), options: [.atomic, .completeFileProtection])
	}
	
	static func load_crates() -> [LRCrate] {
		guard let data = try? Data(contentsOf: path_folder.appending(path: step_crates)) else {
			// Maybe the file doesn’t exist.
			return []
		}
		guard let input: String = String(data: data, encoding: .utf8) else {
			print("Couldn’t decode crates file.")
			return []
		}
		return Parser(input).parse_crates()
	}
	
	fileprivate static let tab = "\t"
	fileprivate static let tab_tab = "\t\t"
	
	private static let path_folder = URL.applicationSupportDirectory.appending(path: "v1/")
	private static let step_crates = "crates"
	static let signposter = OSSignposter(subsystem: "persistence", category: "disk")
}

struct Parser {
	init(_ string: String) {
		self.lines = string.split(separator: "\n", omittingEmptySubsequences: false)
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
			result.append(
				LRCrate(title: String(content), lrAlbums: albums)
			)
		}
		return result
	}
	private func albums_until_outdent(from start: Int) -> (next_i_line: Int, [LRAlbum]) {
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
			let mpidAlbum: MPIDAlbum? = MPIDAlbum(String(content))
			
			guard
				is_album(at: i_line),
				let mpidAlbum
			else {
				// Not an album line. Skip it.
				i_line += 1
				continue
			}
			
			i_line += 1
			let (next_i_line, songs) = songs_until_outdent(from: i_line)
			
			i_line = next_i_line
			guard !songs.isEmpty else {
				// No valid songs for this album. Skip this album line.
				continue
			}
			result.append(
				LRAlbum(mpid: mpidAlbum, lrSongs: songs)
			)
		}
		return (i_line, result)
	}
	private func songs_until_outdent(from start: Int) -> (next_i_line: Int, [LRSong]) {
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
			let mpidSong: MPIDSong? = MPIDSong(String(content))
			
			guard
				is_song(at: i_line),
				let mpidSong
			else {
				// Not a valid song line. Skip it.
				i_line += 1
				continue
			}
			
			i_line += 1
			// TO DO
//			result.append(
//				LRSong(mpid: mpidSong)
//			)
			let _ = mpidSong
			result.append(contentsOf: [])
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
