//
//  PlayheadReflectable.swift
//  LavaRock
//
//  Created by h on 2020-11-07.
//

import UIKit

@MainActor
protocol PlayheadReflectable: AnyObject {
	var spacerSpeakerImageView: UIImageView! { get }
	var speakerImageView: UIImageView! { get }
	var accessibilityValue: String? { get set }
}
extension PlayheadReflectable {
	func reflectPlayhead(containsPlayhead: Bool) {
		spacerSpeakerImageView.maximumContentSizeCategory = .extraExtraExtraLarge
		speakerImageView.maximumContentSizeCategory = spacerSpeakerImageView.maximumContentSizeCategory
		
		let speakerImage: UIImage?
		let newAccessibilityLabel: String?
		defer {
			speakerImageView.image = speakerImage
			accessibilityValue = newAccessibilityLabel
		}
		
		guard
			containsPlayhead,
			let player = TapeDeck.shared.player
		else {
			speakerImage = nil
			newAccessibilityLabel = nil
			return
		}
		if player.playbackState == .playing {
			speakerImage = UIImage(systemName: "speaker.wave.2.fill")
			newAccessibilityLabel = LocalizedString.nowPlaying
		} else {
			speakerImage = UIImage(systemName: "speaker.fill")
			newAccessibilityLabel = LocalizedString.paused
		}
	}
}
