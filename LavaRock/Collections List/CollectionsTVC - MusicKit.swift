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
			case .authorized: break // Should never run
			case .notDetermined:
				let response = await MPMediaLibrary.requestAuthorization()
				
				switch response {
					case .denied, .restricted, .notDetermined: break
					case .authorized: await AppleMusic.integrateIfAuthorized()
					@unknown default: break
				}
			case .denied, .restricted:
				if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
					let _ = await UIApplication.shared.open(settingsURL)
				}
			@unknown default: break
		}
	}
}
