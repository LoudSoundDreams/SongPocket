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
	final let idOfSourceCollection: NSManagedObjectID
	final let idsOfAlbumsBeingMoved: [NSManagedObjectID]
	
	// Helpers
	final var navigationItemPrompt: String {
		let formatString = LocalizedString.formatChooseACollectionPrompt
		let number = idsOfAlbumsBeingMoved.count
		return String.localizedStringWithFormat(
			formatString,
			number)
	}
	final weak var delegate: AlbumMoverDelegate?
	
	// State
	final var didAlreadyMakeNewCollection = false
	final var didAlreadyCommitMoveAlbums = false
	
	init(
		idOfSourceCollection: NSManagedObjectID,
		idsOfAlbumsBeingMoved: [NSManagedObjectID],
		delegate: AlbumMoverDelegate?
	) {
		self.idOfSourceCollection = idOfSourceCollection
		self.idsOfAlbumsBeingMoved = idsOfAlbumsBeingMoved
		self.delegate = delegate
	}
	
	final func suggestedCollectionTitle(
		notMatching existingTitles: Set<String>,
		context: NSManagedObjectContext
	) -> String? {
		let albums = idsOfAlbumsBeingMoved.compactMap {
			context.object(with: $0) as? Album
		}
		for albumMetadataKeyPath in Self.albumMetadataKeyPathsForSuggestingCollectionTitle {
			if
				let suggestion = suggestedCollectionTitle(
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
	
	private func suggestedCollectionTitle(
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
