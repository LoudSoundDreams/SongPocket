//
//  AppleMusic.swift
//  LavaRock
//
//  Created by h on 2023-04-01.
//

import MusicKit

@MainActor
enum AppleMusic {
	static var loadingIndicator: CollectionsTVC? = nil
	
	static func integrateIfAuthorized() async {
		guard MusicAuthorization.currentStatus == .authorized else { return }
		
		await loadingIndicator?.prepareToIntegrateWithAppleMusic()
		
		MusicLibrary.shared.beginWatching() // Collections view must start observing `Notification.Name.mergedChanges` before this.
		TapeDeck.shared.beginWatching()
	}
}
