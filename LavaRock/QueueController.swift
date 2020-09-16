//
//  QueueController.swift
//  LavaRock
//
//  Created by h on 2020-09-14.
//

import CoreData
import MediaPlayer

final class QueueController {
	
	// MARK: - Properties
	
	// Constants
	static let shared = QueueController()
	private let playerController = MPMusicPlayerController.systemMusicPlayer
//	private let coreDataFetchRequest: NSFetchRequest<QueueEntry> = {
//		let request = NSFetchRequest<QueueEntry>(entityName: "QueueEntry")
//		request.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
//		return request
//	}()
	
	// Variables
	private let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
//	var entries = [QueueEntry]() {
//		didSet {
//			for index in 0 ..< entries.count {
//				entries[index].index = Int64(index)
//			}
//		}
//	}
	
	// MARK: - Setup
	
	private init() {
//		reloadEntries()
	}
	
//	private func reloadEntries() {
//		entries = managedObjectContext.objectsFetched(for: coreDataFetchRequest)
//	}
	
	// MARK: -
	
	func setPlayerQueueWith(songsWithObjectIDs songIDs: [NSManagedObjectID]) {
		guard songIDs.count >= 1 else { return } // Do we need this?
		var mediaItems = [MPMediaItem]()
		for songID in songIDs {
			guard
				let song = managedObjectContext.object(with: songID) as? Song,
				let mediaItem = song.mpMediaItem()
			else { continue }
			mediaItems.append(mediaItem)
		}
		let mediaItemCollection = MPMediaItemCollection(items: mediaItems)
		playerController.setQueue(with: mediaItemCollection)
		
		// make and append QueueEntries for our own records
	}
	
	func appendToPlayerQueue(songsWithObjectIDs songIDs: [NSManagedObjectID]) {
		guard songIDs.count >= 1 else { return } // Do we need this?
		var mediaItems = [MPMediaItem]()
		for songID in songIDs {
			guard
				let song = managedObjectContext.object(with: songID) as? Song,
				let mediaItem = song.mpMediaItem()
			else { continue }
			mediaItems.append(mediaItem)
		}
		let mediaItemCollection = MPMediaItemCollection(items: mediaItems)
		let queueDescriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: mediaItemCollection)
		playerController.append(queueDescriptor)
		
		if playerController.playbackState != .playing {
			playerController.prepareToPlay()
		}
		
		// make and append QueueEntries for our own records
	}
	
	func appendToPlayerQueue(songWithObjectID songID: NSManagedObjectID) {
		guard
			let song = managedObjectContext.object(with: songID) as? Song,
			let mediaItem = song.mpMediaItem()
		else { return }
		let mediaItemCollection = MPMediaItemCollection(items: [mediaItem])
		let queueDescriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: mediaItemCollection)
		playerController.append(queueDescriptor)
		
		if playerController.playbackState != .playing {
			playerController.prepareToPlay()
		}
		
		// make and append QueueEntry for our own records
	}
	
}

