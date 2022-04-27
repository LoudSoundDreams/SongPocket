//
//  Notification.Name.swift
//  LavaRock
//
//  Created by h on 2020-09-14.
//

import Foundation

extension Notification.Name {
	static let LRUserChangedAccentColor = Self("user changed accent color")
	static let LRUserRespondedToAllowAccessToMediaLibrary = Self("user responded to “allow access to Music” alert")
	static let LRMergedChanges = Self("merged changes")
	static let LRUserUpdatedDatabase = Self("user updated database")
	static let LRModifiedReel = Self("modified reel")
}
