//
//  extension Notification.Name.swift
//  LavaRock
//
//  Created by h on 2020-09-14.
//

import UIKit

extension Notification.Name {
	static let LRDidChangeAccentColor = Notification.Name("AccentColor has changed some UIWindow’s tintColor. If you find views that don’t automatically reflect this change, make their controllers observe this notification and update those views at this point.")
	static let LRDidSaveChangesFromMusicLibrary = Notification.Name("MusicLibraryManager just saved changes from the built-in Music app’s library into the Core Data store. Instances that depend on the Core Data store should observe this notification and refresh their data now.")
	static let LRDidMoveAlbums = Notification.Name("The user has moved (one or more) Albums to another (existing or new) Collection.")
}
