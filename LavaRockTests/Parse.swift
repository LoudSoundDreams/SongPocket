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
			LRAlbum(id: "13", songs: [
				LRSong(id: "17"),
				LRSong(id: "19"),
				LRSong(id: "23"),
			]),
		]),
		LRCrate(title: "37", albums: [
			LRAlbum(id: "41", songs: [
				LRSong(id: "43"),
			]),
		]),
	])
}
*/
