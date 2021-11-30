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
	
	// Static
	static let metadataKeyPathsForSmartCollectionTitle: [KeyPath<MPMediaItem, String?>] = [
		\.albumArtist,
	]
	
	// Data
	let idsOfAlbumsBeingMoved: [NSManagedObjectID]
	let idsOfAlbumsBeingMoved_asSet: Set<NSManagedObjectID>
	let idsOfSourceCollections: Set<NSManagedObjectID>
	
	// Helpers
	weak var delegate: AlbumMoverDelegate? = nil
	var prompt: String {
		let formatString = FeatureFlag.multicollection ? LocalizedString.formatChooseASectiontoMoveXAlbumsTo : LocalizedString.formatChooseACollectionToMoveXAlbumsTo
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
		for keyPath in Self.metadataKeyPathsForSmartCollectionTitle {
			if
				let suggestedTitle = suggestedCollectionTitle(
					metadataKeyPath: keyPath,
					albums: albums),
				!existingTitles.contains(suggestedTitle)
			{
				return suggestedTitle
			}
		}
		return nil
	}
	
	private func suggestedCollectionTitle(
		metadataKeyPath: KeyPath<MPMediaItem, String?>,
		albums: [Album]
	) -> String? {
		guard let firstSuggestion = albums.first?.suggestedCollectionTitle(
			metadataKeyPath: metadataKeyPath
		) else {
			return nil
		}
		if albums.dropFirst().allSatisfy({
			$0.suggestedCollectionTitle(
				metadataKeyPath: metadataKeyPath
			) == firstSuggestion
		}) {
			return firstSuggestion
		} else {
			return nil
		}
	}
	
}

private extension Album {
	final func suggestedCollectionTitle(
		metadataKeyPath: KeyPath<MPMediaItem, String?>
	) -> String? {
		return mpMediaItemCollection()?.representativeItem?[keyPath: metadataKeyPath]
	}
}
