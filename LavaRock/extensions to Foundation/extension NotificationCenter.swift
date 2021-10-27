//
//  extension NotificationCenter.swift
//  LavaRock
//
//  Created by h on 2021-10-26.
//

import Foundation

extension NotificationCenter {
	
	// Helps observers observe each kind of `Notification` at most once.
	final func removeAndAddObserver(
		_ observer: Any,
		selector: Selector,
		name: Notification.Name,
		object: Any?
	) {
		removeObserver(observer, name: name, object: object)
		addObserver(observer, selector: selector, name: name, object: object)
	}
	
}
