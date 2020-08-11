//
//  MediaPlayerManager.swift
//  LavaRock
//
//  Created by h on 2020-08-10.
//

import MediaPlayer

class MediaPlayerManager {
	
	// MARK: Properties
	
	// "Constants"
	static var library: MPMediaLibrary? = nil
	static let playerController = MPMusicPlayerApplicationController.systemMusicPlayer
	
	// MARK: Methods
	
	init() {
		
		Self.setDefaultLibraryIfAuthorized()
	}
	
	static func setDefaultLibraryIfAuthorized() {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		library = MPMediaLibrary.default()
	}
	
}
