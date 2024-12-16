// 2024-12-15

import Foundation

extension AppleLibrary {
	func merge_from_Apple_Music(
		musicKit sections_unsorted: [MKSection],
		mediaPlayer mediaItems_unsorted: [InfoSong]
	) async {
		is_merging = true
		defer { is_merging = false }
		
//		merge_from_MusicKit(sections_unsorted)
		merge_from_MediaPlayer(mediaItems_unsorted)
	}
	func merge_from_MusicKit(_ sections_unsorted: [MKSection]) {
		let _merge = signposter.beginInterval("merge")
		defer { signposter.endInterval("merge", _merge) }
		
		let new_mkSections: [MKSection] = {
			// Only sort albums themselves; we’ll sort the songs within each album later.
			let now = Date.now
			let sectionsAndDatesCreated: [(section: MKSection, date_created: Date)] = sections_unsorted.map {(
				section: $0,
				date_created: ZZZAlbum.date_created($0.items) ?? now
			)}
			let sorted = sectionsAndDatesCreated.sorted_stably {
				$0.date_created == $1.date_created
			} are_in_order: {
				$0.date_created > $1.date_created
			}
			return sorted.map { $0.section }
		}()
		var fake_id_album_next: MPIDAlbum = 0
		var fake_id_song_next: MPIDSong = 0
		let new_albums: [LRAlbum] = new_mkSections.map { mkSection in
			let id_album = fake_id_album_next
			fake_id_album_next += 1
			
			return LRAlbum(mpidAlbum: id_album, lrSongs: {
				let mkSongs = mkSection.items.sorted {
					SongOrder.precedes_numerically(strict: true, $0, $1)
				}
				return mkSongs.map { _ in
					let id_song = fake_id_song_next
					fake_id_song_next += 1
					
					return LRSong(mpidSong: id_song)
				}
			}())
		}
		let newCrate = LRCrate(title: InterfaceText._tilde, lrAlbums: new_albums)
		
		Disk.save_crates([newCrate])
		LRLibrary.lrCrate = newCrate
	}
}
