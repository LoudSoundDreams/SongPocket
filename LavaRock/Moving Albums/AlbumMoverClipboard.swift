//
//  AlbumMoverClipboard.swift
//  LavaRock
//
//  Created by h on 2020-08-04.
//

import CoreData
import MediaPlayer

protocol AlbumMoverDelegate: AnyObject {
	func didMoveThenDismiss()
}

final class AlbumMoverClipboard { // This is a class and not a struct because we use it to share information.
	
	// Data
	let idsOfAlbumsBeingMoved: [NSManagedObjectID]
	let idsOfAlbumsBeingMoved_asSet: Set<NSManagedObjectID>
	let idsOfSourceCollections: Set<NSManagedObjectID>
	
	// Helpers
	weak var delegate: AlbumMoverDelegate? = nil
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
		delegate: AlbumMoverDelegate
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
		let albums = idsOfAlbumsBeingMoved.compactMap {
			context.object(with: $0) as? Album
		}
		if
			let suggestedTitle = suggestedCollectionTitle(albums: albums),
			!existingTitles.contains(suggestedTitle)
		{
			return suggestedTitle
		} else {
			return nil
		}
	}
	
	private func suggestedCollectionTitle(
		albums: [Album]
	) -> String? {
		guard let firstAlbum = albums.first else { return nil }
		
		let firstSuggestion = firstAlbum.albumArtistFormattedOrPlaceholder()
		
		if albums.dropFirst().allSatisfy({
			$0.albumArtistFormattedOrPlaceholder() == firstSuggestion
		}) {
			return firstSuggestion
		} else {
			return nil
		}
	}
	
}
