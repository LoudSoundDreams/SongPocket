//
//  PlayheadReflectable.swift
//  LavaRock
//
//  Created by h on 2020-11-07.
//

import UIKit

typealias PlayheadReflectable = _PlayheadReflectable & CachesBodyOfAccessibilityLabel

protocol CachesBodyOfAccessibilityLabel {
	var bodyOfAccessibilityLabel: String? { get }
}

@MainActor
protocol _PlayheadReflectable: AnyObject {
	var spacerSpeakerImageView: UIImageView! { get }
	var speakerImageView: UIImageView! { get }
	var accessibilityLabel: String? { get set }
}
extension _PlayheadReflectable {
	func reflectPlayhead(
		containsPlayhead: Bool,
		bodyOfAccessibilityLabel: String? // Force callers to pass this in manually, to help them remember to update it beforehand.
	) {
		spacerSpeakerImageView.maximumContentSizeCategory = .extraExtraExtraLarge
		speakerImageView.maximumContentSizeCategory = spacerSpeakerImageView.maximumContentSizeCategory
		
		let speakerImage: UIImage?
		let headOfAccessibilityLabel: String?
		defer {
			speakerImageView.image = speakerImage
			accessibilityLabel = [
				headOfAccessibilityLabel,
				bodyOfAccessibilityLabel,
			].compactedAndFormattedAsNarrowList()
		}
		
		guard
			containsPlayhead,
			let player = TapeDeck.shared.player
		else {
			speakerImage = nil
			headOfAccessibilityLabel = nil
			return
		}
		if player.playbackState == .playing {
			speakerImage = UIImage(systemName: "speaker.wave.2.fill")
			headOfAccessibilityLabel = LocalizedString.nowPlaying
		} else {
			speakerImage = UIImage(systemName: "speaker.fill")
			headOfAccessibilityLabel = LocalizedString.paused
		}
	}
}
