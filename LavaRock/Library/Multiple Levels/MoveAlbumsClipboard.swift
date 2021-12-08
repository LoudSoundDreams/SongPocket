//
//  MoveAlbumsClipboard.swift
//  LavaRock
//
//  Created by h on 2020-08-04.
//

import CoreData
import MediaPlayer

protocol MoveAlbumsDelegate: AnyObject {
	func didMoveThenDismiss()
}

final class MoveAlbumsClipboard { // This is a class and not a struct because we use it to share information.
	
	// Data
	let idsOfAlbumsBeingMoved: [NSManagedObjectID]
	let idsOfAlbumsBeingMoved_asSet: Set<NSManagedObjectID>
	let idsOfSourceCollections: Set<NSManagedObjectID>
	
	// Helpers
	weak var delegate: MoveAlbumsDelegate? = nil
	var prompt: String {
		let formatString = FeatureFlag.multicollection ? LocalizedString.format_chooseASectiontoMoveXAlbumsTo : LocalizedString.format_chooseACollectionToMoveXAlbumsTo
		let number = idsOfAlbumsBeingMoved.count
		return String.localizedStringWithFormat(
			formatString,
			number)
	}
	
	// State
	var didAlreadyCreate = false
	var didAlreadyCommitMove = false
	
	init(
		albumsBeingMoved: [Album],
		delegate: MoveAlbumsDelegate
	) {
		idsOfAlbumsBeingMoved = albumsBeingMoved.map { $0.objectID }
		idsOfAlbumsBeingMoved_asSet = Set(idsOfAlbumsBeingMoved)
		idsOfSourceCollections = Set(albumsBeingMoved.map { $0.container!.objectID })
		self.delegate = delegate
	}
	
	func smartCollectionTitle(
		notMatching existingTitles: Set<String>,
		context: NSManagedObjectContext
	) -> String? {
		let albumsOutOfOrder = idsOfAlbumsBeingMoved.compactMap {
			context.object(with: $0) as? Album
		}
		guard let someAlbum = albumsOutOfOrder.first else {
			return nil
		}
		let otherAlbums = albumsOutOfOrder.dropFirst()
		// Don't query for all the album artists upfront, because that's slow.
		
		// Check whether the album artists of the albums we're moving are all identical.
	albumArtistIdentical: do {
		let someAlbumArtist = someAlbum.albumArtistFormattedOrPlaceholder()
		guard !existingTitles.contains(someAlbumArtist) else {
			break albumArtistIdentical
		}
		if otherAlbums.allSatisfy({
			$0.albumArtistFormattedOrPlaceholder() == someAlbumArtist
		}) {
			return someAlbumArtist
		}
	}
		
		// Check whether the album artists of the albums we're moving all start with the same thing.
		/*
	albumArtistCommonPrefix: do {
		let commonPrefixTrimmed = albumsOutOfOrder.commonPrefixLazilyGeneratingStringsToCompare {
			$0.albumArtistFormattedOrPlaceholder()
		}.trimmingWhitespaceAtEnd()
		guard !existingTitles.contains(commonPrefixTrimmed) else {
			break albumArtistCommonPrefix
		}
		// TO DO: Internationalize
		let commonPrefixLength = commonPrefixTrimmed.count
		let commonPrefixTrimmedIsAtWordBoundary = albumsOutOfOrder.allSatisfy {
			let albumArtist = $0.albumArtistFormattedOrPlaceholder()
			return albumArtist.endsOrHasWhitespaceAfter(dropFirstCount: commonPrefixLength)
		}
		if commonPrefixTrimmedIsAtWordBoundary {
			return commonPrefixTrimmed
		}
	}
		*/
		
		// Otherwise, give up.
		return nil
	}
	
}
