//
//  Avatar.swift
//  LavaRock
//
//  Created by h on 2022-07-30.
//

import Foundation

extension Notification.Name {
	static var userChangedAvatar: Self { Self("user changed avatar") }
}

struct Avatar {
	let pausedImageName: String
	let playingImageName: String
	
	static var current: Self = Avatar(
		pausedImageName: "speaker.fill",
		playingImageName: "speaker.wave.2.fill")
	
	static let all: [Self] = {
		if #available(iOS 16.0, *) {
			return [
				Avatar(
					pausedImageName: "speaker.fill",
					playingImageName: "speaker.wave.2.fill"),
				Avatar(
					pausedImageName: "arrowshape.forward",
					playingImageName: "arrowshape.forward.fill"),
				Avatar(
					pausedImageName: "bird",
					playingImageName: "bird.fill"),
				Avatar(
					pausedImageName: "fish",
					playingImageName: "fish.fill"),
				Avatar(
					pausedImageName: "beach.umbrella",
					playingImageName: "beach.umbrella.fill"),
				Avatar(
					pausedImageName: "sailboat",
					playingImageName: "sailboat.fill"),
			]
		} else {
			return [
				Avatar(
					pausedImageName: "speaker.fill",
					playingImageName: "speaker.wave.2.fill"),
				Avatar(
					pausedImageName: "hifispeaker",
					playingImageName: "hifispeaker.fill"),
			]
		}
	}()
}
