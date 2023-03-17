//
//  PlayheadReflectable.swift
//  LavaRock
//
//  Created by h on 2020-11-07.
//

import UIKit

@MainActor
protocol PlayheadReflectable: AnyObject {
	// Adopting types must …
	// • Call `reflectPlayhead` whenever appropriate.
	
	var spacerSpeakerImageView: UIImageView! { get }
	var speakerImageView: UIImageView! { get }
	static var usesUIKitAccessibility__: Bool { get }
	
	func reflectPlayhead(
		containsPlayhead: Bool
	)
}
extension PlayheadReflectable {
	func freshen_avatar_imageView(
		containsPlayhead: Bool
	) {
		spacerSpeakerImageView.maximumContentSizeCategory = .extraExtraExtraLarge
		speakerImageView.maximumContentSizeCategory = spacerSpeakerImageView.maximumContentSizeCategory
		
		spacerSpeakerImageView.image = UIImage(systemName: Avatar.preference.playingSFSymbolName)
		
		let speakerImage: UIImage?
		defer {
			speakerImageView.image = speakerImage
		}
		
#if targetEnvironment(simulator)
		guard containsPlayhead else {
			speakerImage = nil
			return
		}
		speakerImage = UIImage(systemName: Avatar.preference.pausedSFSymbolName)
#else
		guard
			containsPlayhead,
			let player = TapeDeck.shared.player
		else {
			speakerImage = nil
			return
		}
		if player.playbackState == .playing {
			speakerImage = UIImage(systemName: Avatar.preference.playingSFSymbolName)
		} else {
			speakerImage = UIImage(systemName: Avatar.preference.pausedSFSymbolName)
		}
#endif
	}
	
	func create_accessibilityLabel(
		containsPlayhead: Bool,
		rowContentAccessibilityLabel__: String?
	) -> String? {
		let now_playing_status: String? = {
			guard
				containsPlayhead,
				let player = TapeDeck.shared.player
			else {
				return nil
			}
			if player.playbackState == .playing {
				return LRString.nowPlaying
			} else {
				return LRString.paused
			}
		}()
		
		return [
			now_playing_status,
			rowContentAccessibilityLabel__,
		].compactedAndFormattedAsNarrowList()
	}
}
