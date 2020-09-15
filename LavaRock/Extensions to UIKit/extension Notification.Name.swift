//
//  extension Notification.Name.swift
//  LavaRock
//
//  Created by h on 2020-09-14.
//

import UIKit

extension Notification.Name {
	static let LRDidChangeAccentColor = Notification.Name("AccentColorManager has changed some UIWindow’s tintColor. If you find views that don’t automatically reflect this change, make their controllers observe this notification and update those views at this point.")
	static let LRDidReceiveAuthorizationForAppleMusic = Notification.Name("The user just gave us permission to access their Apple Music library. Objects that depend on the Apple Music library should observe this notification and update now.")
	static let LRDidSaveChangesFromAppleMusic = Notification.Name("AppleMusicLibraryManager just saved changes from the Apple Music library into the Core Data store. Objects that depend on the Core Data store should observe this notification and refresh their data now.")
}
