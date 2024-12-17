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
	}
}
