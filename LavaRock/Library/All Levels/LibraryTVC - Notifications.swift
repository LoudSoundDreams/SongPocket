//
//  LibraryTVC - Notifications.swift
//  LavaRock
//
//  Created by h on 2020-08-29.
//

import Foundation

extension LibraryTVC: TapeDeckReflecting {
	final func reflect_playback_mode() {
		reflectPlayhead_library()
	}
	
	final func reflect_now_playing_item() {
		reflectPlayhead_library()
	}
}
