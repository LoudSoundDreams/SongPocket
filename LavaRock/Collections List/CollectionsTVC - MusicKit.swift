//
//  CollectionsTVC - MusicKit.swift
//  LavaRock
//
//  Created by h on 2023-11-05.
//

import MediaPlayer
import UIKit

extension CollectionsTVC {
	func requestAccessToAppleMusic() async {
		switch MPMediaLibrary.authorizationStatus() {
			case .notDetermined:
				let authorizationStatus = await MPMediaLibrary.requestAuthorization()
				
				switch authorizationStatus {
					case .authorized:
						await AppleMusic.integrateIfAuthorized()
					case .notDetermined, .denied, .restricted: break
					@unknown default: break
				}
			case .authorized: break // Should never run
			case .denied, .restricted:
				if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
					let _ = await UIApplication.shared.open(settingsURL)
				}
			@unknown default: break
		}
	}
}
