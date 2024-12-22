// 2024-09-04

final class LRCrate {
	let title: String
	var lrAlbums: [LRAlbum] = []
	
	init(title: String) {
		self.title = title
	}
}
final class LRAlbum {
	let mpid: MPIDAlbum
	weak var lrCrate: LRCrate!
	var lrSongs: [LRSong] = []
	
	init(mpid: MPIDAlbum, parent: LRCrate) {
		self.mpid = mpid
		lrCrate = parent
	}
}
final class LRSong {
	let mpid: MPIDSong
	weak var lrAlbum: LRAlbum!
	
	init(mpid: MPIDSong, parent: LRAlbum) {
		self.mpid = mpid
		lrAlbum = parent
	}
}

@MainActor struct Librarian {
	private(set) static var the_lrCrate: LRCrate?
	static func lrAlbum_with(mpid: MPIDAlbum) -> LRAlbum? {
		return lrAlbums[mpid]?.referencee
	}
	static func lrSong_with(mpid: MPIDSong) -> LRSong? {
		return lrSongs[mpid]?.referencee
	}
	
	private static var lrAlbums: [MPIDAlbum: WeakRef<LRAlbum>] = [:]
	private static var lrSongs: [MPIDSong: WeakRef<LRSong>] = [:]
	
	static func _remove_lrCrate(_ lrCrate_to_remove: LRCrate) {
		// TO DO
	}
	
	static func append_lrAlbum(mpid: MPIDAlbum) -> LRAlbum {
		if the_lrCrate == nil {
			the_lrCrate = LRCrate(title: InterfaceText._tilde)
		}
		let the_lrCrate = the_lrCrate!
		
		let lrAlbum_new = LRAlbum(mpid: mpid, parent: the_lrCrate)
		lrAlbums[mpid] = WeakRef(lrAlbum_new)
		the_lrCrate.lrAlbums.append(lrAlbum_new)
		return lrAlbum_new
	}
	static func append_lrSong(mpid: MPIDSong, in parent: LRAlbum) {
		let lrSong_new = LRSong(mpid: mpid, parent: parent)
		lrSongs[mpid] = WeakRef(lrSong_new)
		parent.lrSongs.append(lrSong_new)
	}
	
	static func save() {
		// TO DO
	}
	static func load() {
		// TO DO
	}
	
	static func debug_Print() {
		Print()
		guard let the_lrCrate else {
			Print("nil crate")
			return
		}
		Print("crate tree")
		Print(the_lrCrate.title)
		the_lrCrate.lrAlbums.forEach { lrAlbum in
			Print("  \(lrAlbum.mpid) in \(lrAlbum.lrCrate.title)")
			lrAlbum.lrSongs.forEach { lrSong in
				Print("    \(lrSong.mpid) in \(lrSong.lrAlbum.mpid)")
			}
		}
		
		Print()
		Print("album dict")
		lrAlbums.forEach { (mpidAlbum, lrAlbum_ref) in
			var value_description = "nil"
			if let lrAlbum = lrAlbum_ref.referencee {
				value_description = "\(ObjectIdentifier(lrAlbum).debugDescription), \(lrAlbum.mpid)"
			}
			Print("\(mpidAlbum) → \(value_description)")
		}
		
		Print()
		Print("song dict")
		lrSongs.forEach { (mpidSong, lrSong_ref) in
			var value_description = "nil"
			if let lrSong = lrSong_ref.referencee {
				value_description = "\(ObjectIdentifier(lrSong).debugDescription), \(lrSong.mpid)"
			}
			Print("\(mpidSong) → \(value_description)")
		}
	}
}
