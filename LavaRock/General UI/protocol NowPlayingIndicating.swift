//
//  protocol NowPlayingIndicating.swift
//  LavaRock
//
//  Created by h on 2020-11-07.
//

import UIKit

@MainActor
protocol NowPlayingIndicating: AnyObject {
	var spacerSpeakerImageView: UIImageView! { get }
	var speakerImageView: UIImageView! { get }
	var accessibilityValue: String? { get set }
}
extension NowPlayingIndicating {
	func indicateNowPlaying(containsPlayhead: Bool) {
		spacerSpeakerImageView.maximumContentSizeCategory = .extraExtraExtraLarge
		speakerImageView.maximumContentSizeCategory = spacerSpeakerImageView.maximumContentSizeCategory
		
		guard
			containsPlayhead,
			let player = TapeDeck.shared.player
		else {
			speakerImageView.image = nil
			accessibilityValue = nil
			return
		}
		if player.playbackState == .playing {
			speakerImageView.image = UIImage(systemName: "speaker.wave.2.fill")
			accessibilityValue = LocalizedString.nowPlaying // For some reason, `UITableViewCell.accessibilityLabel == nil` at this point.
		} else {
			speakerImageView.image = UIImage(systemName: "speaker.fill")
			accessibilityValue = LocalizedString.paused
		}
	}
}
