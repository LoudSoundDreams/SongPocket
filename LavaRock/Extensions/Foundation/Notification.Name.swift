//
//  Notification.Name.swift
//  LavaRock
//
//  Created by h on 2020-09-14.
//

import Foundation

extension Notification.Name {
	static let LRMediaLibraryAuthorizationStatusDidChange = Self("The user responded to the “‘Songpocket’ would like to access your Apple Music, your music and video activity, and your media library” alert.")
	static let LRDidMergeChanges = Self("`MusicLibraryManager` saved changes from the built-in Music app’s library into the Core Data store. Instances that depend on that fact should observe this notification and freshen their data now.")
	static let LRUserDidUpdateDatabase = Self("The user moved `Album`s and might have created new `Collection`s.")
	static let LRReelDidChange = Self("Something set `Reel.contents`.")
}
