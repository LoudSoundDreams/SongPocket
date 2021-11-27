//
//  AlbumMoverClipboard.swift
//  LavaRock
//
//  Created by h on 2020-08-04.
//

import CoreData
import MediaPlayer

final class AlbumMoverClipboard { // This is a class and not a struct because we use it to share information.
	
	// Static
	static let metadataKeyPathsForSmartCollectionTitle: [KeyPath<MPMediaItem, String?>] = [
		// Order matters. First, we'll see if all the Albums have the same album artist; if they don't, then we'll try the next case, and so on.
		\.albumArtist,
	]
	
	// Instance
	final let idsOfAlbumsBeingMoved: [NSManagedObjectID]
	final let idsOfAlbumsBeingMoved_asSet: Set<NSManagedObjectID>
	final let idsOfSourceCollections: Set<NSManagedObjectID>
	
	// Helpers
	final var navigationItemPrompt: String {
		let formatString = FeatureFlag.multicollection ? LocalizedString.formatChooseASectionPrompt : LocalizedString.formatChooseACollectionPrompt
		let number = idsOfAlbumsBeingMoved.count
		return String.localizedStringWithFormat(
			formatString,
			number)
	}
	final weak var delegate: AlbumMoverDelegate?
	
	// State
	final var didAlreadyCreateCollection = false
	final var didAlreadyCommitMoveAlbums = false
	
	init(
		idsOfAlbumsBeingMoved: [NSManagedObjectID],
		idsOfSourceCollections: Set<NSManagedObjectID>,
		delegate: AlbumMoverDelegate?
	) {
		self.idsOfAlbumsBeingMoved = idsOfAlbumsBeingMoved
		idsOfAlbumsBeingMoved_asSet = Set(idsOfAlbumsBeingMoved)
		self.idsOfSourceCollections = idsOfSourceCollections
		self.delegate = delegate
	}
	
	final func smartCollectionTitle(
		notMatching existingTitles: Set<String>,
		context: NSManagedObjectContext
	) -> String? {
		let albums = idsOfAlbumsBeingMoved.compactMap {
			context.object(with: $0) as? Album
		}
		for keyPath in Self.metadataKeyPathsForSmartCollectionTitle {
			if
				let suggestedTitle = suggestedCollectionTitle(metadataKeyPath: keyPath, albums: albums),
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
		guard let firstSuggestion = albums.first?.suggestedCollectionTitle(metadataKeyPath: metadataKeyPath) else {
			return nil
		}
		if albums.dropFirst().allSatisfy({
			$0.suggestedCollectionTitle(metadataKeyPath: metadataKeyPath) == firstSuggestion
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
