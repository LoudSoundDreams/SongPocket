// 2024-08-30

import Foundation
import os

enum Disk {
	static func save(_ crates: [LRCrate]) { // 10,000 albums and 12,000 songs takes 40ms in 2024.
		let filer = FileManager.default
		try! filer.createDirectory(at: pFolder, withIntermediateDirectories: true)
		
		let signposter = OSSignposter(subsystem: "persistence", category: "disk")
		let _serialize = signposter.beginInterval("serialize")
		var output: String = ""
		crates.forEach {
			output.append(contentsOf: "\($0.title)\n")
			$0.albums.forEach { album in
				output.append(contentsOf: "\(tAlbum)\(album.mpidAlbum)\n")
				album.songs.forEach { song in
					output.append(contentsOf: "\(ttSong)\(song.mpidSong)\n")
				}
			}
		}
		signposter.endInterval("serialize", _serialize)
		let data = Data(output.utf8)
		try! data.write(to: pFolder.appending(path: cCrates), options: [.atomic, .completeFileProtection])
	}
	
	static func loadCrates() -> [LRCrate] {
		guard let data = try? Data(contentsOf: pFolder.appending(path: cCrates)) else {
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
	
	private static let pFolder = URL.applicationSupportDirectory.appending(path: "v1/")
	private static let cCrates = "crates"
}

struct Parser {
	private let signposter = OSSignposter(subsystem: "persistence", category: "parser")
	
	init(_ string: String) {
		self.lines = string.split(separator: "\n", omittingEmptySubsequences: false)
	}
	private let lines: [Substring]
	
	func crates() -> [LRCrate] {
		let _crates = signposter.beginInterval("crates")
		defer { signposter.endInterval("crates", _crates) }
		
		var result: [LRCrate] = []
		var iLine = 0
		while iLine < lines.count {
			let content = lines[iLine]
			
			guard isCrate(at: iLine) else {
				// Not a crate line. Skip it.
				iLine += 1
				continue
			}
			
			iLine += 1
			let (nextILine, albums) = albumsUntilOutdent(from: iLine)
			
			iLine = nextILine
			guard !albums.isEmpty else {
				// No valid albums for this crate. Skip this crate line.
				continue
			}
			result.append(
				LRCrate(title: String(content), albums: albums)
			)
		}
		return result
	}
	private func albumsUntilOutdent(from start: Int) -> (nextILine: Int, [LRAlbum]) {
		let _albums = signposter.beginInterval("albums")
		defer { signposter.endInterval("albums", _albums) }
		
		var result: [LRAlbum] = []
		var iLine = start
		while
			iLine < lines.count,
			!isCrate(at: iLine) // Parse albums until outdent.
		{
			let line = lines[iLine]
			let content = line.dropFirst(Disk.tAlbum.count)
			let mpidAlbum: MPID? = MPID(String(content))
			
			guard
				isAlbum(at: iLine),
				let mpidAlbum
			else {
				// Not an album line. Skip it.
				iLine += 1
				continue
			}
			
			iLine += 1
			let (nextILine, songs) = songsUntilOutdent(from: iLine)
			
			iLine = nextILine
			guard !songs.isEmpty else {
				// No valid songs for this album. Skip this album line.
				continue
			}
			result.append(
				LRAlbum(mpidAlbum: mpidAlbum, songs: songs)
			)
		}
		return (iLine, result)
	}
	private func songsUntilOutdent(from start: Int) -> (nextILine: Int, [LRSong]) {
		let _songs = signposter.beginInterval("songs")
		defer { signposter.endInterval("songs", _songs) }
		
		var result: [LRSong] = []
		var iLine = start
		while
			iLine < lines.count,
			!isCrate(at: iLine), !isAlbum(at: iLine) // Parse songs until outdent.
		{
			let line = lines[iLine]
			let content = line.dropFirst(Disk.ttSong.count)
			let mpidSong: MPID? = MPID(String(content))
			
			guard
				isSong(at: iLine),
				let mpidSong
			else {
				// Not a valid song line. Skip it.
				iLine += 1
				continue
			}
			
			iLine += 1
			result.append(
				LRSong(mpidSong: mpidSong)
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
