//
//  LibraryTVC - Notifications.swift
//  LavaRock
//
//  Created by h on 2020-08-29.
//

import Foundation

extension Notification.Name {
	static let userUpdatedDatabase = Self("user updated database")
}

extension LibraryTVC: TapeDeckReflecting {
	final func reflectPlaybackState() {
		reflectPlayhead_library()
	}
	
	final func reflectNowPlayingItem() {
		reflectPlayhead_library()
	}
}
