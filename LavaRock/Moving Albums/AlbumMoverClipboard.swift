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
	static let albumMetadataKeyPathsForSuggestingCollectionTitle = [
		// Order matters. First, we'll see if all the Albums have the same album artist; if they don't, then we'll try the next case, and so on.
		\MPMediaItem.albumArtist,
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
		for albumMetadataKeyPath in Self.albumMetadataKeyPathsForSuggestingCollectionTitle {
			if
				let suggestion = smartCollectionTitle(
					albumMetadataKeyPath: albumMetadataKeyPath,
					albums: albums,
					context: context),
				!existingTitles.contains(suggestion)
			{
				return suggestion
			}
		}
		return nil
	}
	
	private func smartCollectionTitle(
		albumMetadataKeyPath: KeyPath<MPMediaItem, String?>,
		albums: [Album],
		context: NSManagedObjectContext
	) -> String? {
		var runningSuggestion: String? = nil
		for album in albums {
			guard let suggestion = album.mpMediaItemCollection()?.representativeItem?[keyPath: albumMetadataKeyPath] else { continue }
			if suggestion != runningSuggestion {
				if runningSuggestion == nil {
					runningSuggestion = suggestion
				} else {
					return nil
				}
			}
		}
		return runningSuggestion
	}
	
}
