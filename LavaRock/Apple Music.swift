//
//  Apple Music.swift
//  LavaRock
//
//  Created by h on 2022-03-19.
//

import MusicKit

@MainActor enum AppleMusic {
	static var loadingIndicator: CollectionsTVC? = nil
	
	static func integrateIfAuthorized() async {
		guard MusicAuthorization.currentStatus == .authorized else { return }
		
		await loadingIndicator?.prepareToIntegrateWithAppleMusic()
		
		MusicLibrary.shared.beginWatching() // Collections view must start observing `Notification.Name.mergedChanges` before this.
		TapeDeck.shared.beginWatching()
	}
}

@MainActor extension SystemMusicPlayer {
	static var sharedIfAuthorized: SystemMusicPlayer? {
		guard MusicAuthorization.currentStatus == .authorized else {
			return nil
		}
		return .shared
	}
}

import MediaPlayer
extension MPMusicPlayerController {
	static var systemMusicPlayerIfAuthorized: MPMusicPlayerController? {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return nil
		}
		return .systemMusicPlayer
	}
}
