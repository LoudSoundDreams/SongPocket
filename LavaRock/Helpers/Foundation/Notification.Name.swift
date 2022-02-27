//
//  Notification.Name.swift
//  LavaRock
//
//  Created by h on 2020-09-14.
//

import Foundation

extension Notification.Name {
	static let LRDidMergeChanges = Notification.Name("`MusicLibraryManager` has saved changes from the built-in Music app’s library into the Core Data store. Instances that depend on that fact should observe this notification and freshen their data now.")
	static let LRUserDidUpdateDatabase = Notification.Name("The user has moved `Album`s and might have created new `Collection`s.")
}
