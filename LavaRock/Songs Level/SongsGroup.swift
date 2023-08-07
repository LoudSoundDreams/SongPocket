//
//  SongsGroup.swift
//  LavaRock
//
//  Created by h on 2021-07-02.
//

import CoreData

extension SongsGroup: LibraryGroup {}
struct SongsGroup {
	// `LibraryGroup`
	let container: NSManagedObject?
	var items: [NSManagedObject] {
		didSet {
			_reindex()
		}
	}
	
	let trackNumberSpacer: String
	
	init(
		album: Album?,
		context: NSManagedObjectContext
	) {
		container = album
		items = Song.allFetched(sorted: true, inAlbum: album, context: context)
		
		let defaultSpacer = "00"
		guard let representative = album?.representativeSongInfo() else {
			trackNumberSpacer = defaultSpacer
			return
		}
		
		let infos: [SongInfo] = items.compactMap { ($0 as? Song)?.songInfo() }
		// At minimum, reserve the width of 2 digits, plus an interpunct if appropriate.
		// At maximum, reserve the width of 4 digits plus an interpunct.
		if representative.shouldShowDiscNumber {
			var widestText = defaultSpacer
			for info in infos {
				let discAndTrack = ""
				+ info.discNumberFormatted()
				+ (info.trackNumberFormattedOptional() ?? "")
				if discAndTrack.count >= 4 {
					trackNumberSpacer = LRString.interpunct + "0000"
					return
				}
				if discAndTrack.count > widestText.count {
					widestText = discAndTrack
				}
			}
			trackNumberSpacer = LRString.interpunct + widestText
		} else {
			var widestText = defaultSpacer
			for info in infos {
				let track = info.trackNumberFormattedOptional() ?? ""
				if track.count >= 4 {
					trackNumberSpacer = "0000"
					return
				}
				if track.count > widestText.count {
					widestText = track
				}
			}
			trackNumberSpacer = String(widestText)
			return
		}
	}
}
