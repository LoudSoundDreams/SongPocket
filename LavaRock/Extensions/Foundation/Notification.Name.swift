//
//  Notification.Name.swift
//  LavaRock
//
//  Created by h on 2023-04-01.
//

import Foundation

extension Notification.Name {
	static var user_changed_avatar: Self {
		Self("user changed avatar")
	}
	
	static var mergedChanges: Self {
		Self("merged changes")
	}
	
	static var userUpdatedDatabase: Self {
		Self("user updated database")
	}
}
