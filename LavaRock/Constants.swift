//
//  Constants.swift
//  LavaRock
//
//  Created by h on 2021-10-26.
//

extension Double {
	static var oneEighth: Self { 1/8 }
	static var oneFourth: Self { 1/4 }
	static var oneHalf: Self { 1/2 }
}
extension Float {
	static var oneFourth: Self { 1/4 }
}
extension CGFloat {
	static var oneHalf: Self { 1/2 }
	static var eight: Self { 8 }
}

import SwiftUI
enum LRColor {
	static let grey_oneEighth = Color(
		hue: 0,
		saturation: 0,
		brightness: 1/8
	)
}

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

import OSLog
extension OSLog {
	private static let music_library = "4. MusicLibrary"
	static let merge = OSLog(
		subsystem: music_library,
		category: "A. Main")
	static let update = OSLog(
		subsystem: music_library,
		category: "B. Update")
	static let create = OSLog(
		subsystem: music_library,
		category: "C. Create")
	static let cleanup = OSLog(
		subsystem: music_library,
		category: "E. Cleanup")
}
