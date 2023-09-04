//
//  Notifications.swift
//  LavaRock
//
//  Created by h on 2021-10-26.
//

import Foundation

extension Notification.Name {
	static let LRMergedChanges = Self("merged changes")
	static let LRUserUpdatedDatabase = Self("user updated database")
}

extension NotificationCenter {
	// Helps callers observe each kind of `Notification` exactly once.
	final func addObserverOnce(
		_ observer: Any,
		selector: Selector,
		name: Notification.Name,
		object: Any?
	) {
		removeObserver(observer, name: name, object: object)
		addObserver(observer, selector: selector, name: name, object: object)
	}
}
