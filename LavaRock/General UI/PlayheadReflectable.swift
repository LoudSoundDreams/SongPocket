//
//  PlayheadReflectable.swift
//  LavaRock
//
//  Created by h on 2020-11-07.
//

import UIKit

typealias PlayheadReflectable = _PlayheadReflectable & CachesBodyOfAccessibilityLabel

@MainActor
protocol CachesBodyOfAccessibilityLabel {
	var rowContentAccessibilityLabel__: String? { get }
}

@MainActor
protocol _PlayheadReflectable: AnyObject {
	// Adopting types must …
	// • Call `reflectPlayhead` whenever appropriate.
	
	var spacerSpeakerImageView: UIImageView! { get }
	var speakerImageView: UIImageView! { get }
	static var usesUIKitAccessibility__: Bool { get }
	var accessibilityLabel: String? { get set }
}
extension _PlayheadReflectable {
	func reflectPlayhead(
		containsPlayhead: Bool,
		rowContentAccessibilityLabel__: String? // Force callers to pass this in manually, to help them remember to update it beforehand.
	) {
		spacerSpeakerImageView.maximumContentSizeCategory = .extraExtraExtraLarge
		speakerImageView.maximumContentSizeCategory = spacerSpeakerImageView.maximumContentSizeCategory
		
		spacerSpeakerImageView.image = UIImage(systemName: Avatar.preference.playingSFSymbolName)
		
		let speakerImage: UIImage?
		let nowPlayingStatusAccessibilityLabel__: String?
		defer {
			speakerImageView.image = speakerImage
			if Self.usesUIKitAccessibility__ {
				accessibilityLabel = [
					nowPlayingStatusAccessibilityLabel__,
					rowContentAccessibilityLabel__,
				].compactedAndFormattedAsNarrowList()
			}
		}
		
#if targetEnvironment(simulator)
		guard containsPlayhead else {
			speakerImage = nil
			headOfAccessibilityLabel = nil
			return
		}
		speakerImage = UIImage(systemName: Avatar.preference.pausedSFSymbolName)
		headOfAccessibilityLabel = LRString.paused
#else
		guard
			containsPlayhead,
			let player = TapeDeck.shared.player
		else {
			speakerImage = nil
			nowPlayingStatusAccessibilityLabel__ = nil
			return
		}
		if player.playbackState == .playing {
			speakerImage = UIImage(systemName: Avatar.preference.playingSFSymbolName)
			nowPlayingStatusAccessibilityLabel__ = LRString.nowPlaying
		} else {
			speakerImage = UIImage(systemName: Avatar.preference.pausedSFSymbolName)
			nowPlayingStatusAccessibilityLabel__ = LRString.paused
		}
#endif
	}
}
