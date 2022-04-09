//
//  protocol NowPlayingIndicating.swift
//  LavaRock
//
//  Created by h on 2020-11-07.
//

import UIKit

@MainActor
protocol NowPlayingIndicating {
	var spacerSpeakerImageView: UIImageView! { get }
	var speakerImageView: UIImageView! { get }
	var accessibilityValue: String? { get set }
}
extension NowPlayingIndicating {
	mutating func indicateNowPlaying(isInPlayer: Bool) {
		spacerSpeakerImageView.maximumContentSizeCategory = .extraExtraExtraLarge
		speakerImageView.maximumContentSizeCategory = .extraExtraLarge
		
		guard
			isInPlayer,
			let player = PlayerWatcher.shared.player
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
