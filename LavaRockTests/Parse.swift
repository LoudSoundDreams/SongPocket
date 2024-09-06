// 2024-09-01
/*
import Testing
@testable import LavaRock

private let badStructure: String = """
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
47
	53
		
"""

@Test private func parseBadStructure() {
	let crates = Parser(badStructure).crates()
	#expect(crates == [
		LRCrate(title: "7", albums: [
			LRAlbum(mpAlbumID: MPID("13")!, songs: [
				LRSong(mpSongID: MPID("17")!),
				LRSong(mpSongID: MPID("19")!),
				LRSong(mpSongID: MPID("23")!),
			]),
		]),
		LRCrate(title: "", albums: [
			LRAlbum(mpAlbumID: MPID("41")!, songs: [
				LRSong(mpSongID: MPID("43")!),
			]),
		]),
	])
}
*/
