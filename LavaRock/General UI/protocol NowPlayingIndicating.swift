//
//  protocol NowPlayingIndicating.swift
//  LavaRock
//
//  Created by h on 2020-11-07.
//

import UIKit

@MainActor
protocol NowPlayingDetermining {
	func isInPlayer(anyIndexPath: IndexPath) -> Bool
}

protocol NowPlayingIndicating {
	var spacerSpeakerImageView: UIImageView! { get set }
	var speakerImageView: UIImageView! { get set }
	var accessibilityValue: String? { get set }
}
extension NowPlayingIndicating {
	mutating func indicateNowPlaying(
		isInPlayer: Bool,
		isPlaying: Bool
	) {
		guard isInPlayer else {
			speakerImageView.image = nil
			accessibilityValue = nil
			return
		}
		if isPlaying {
			speakerImageView.image = UIImage(systemName: .SFSpeakerWave)
			accessibilityValue = LocalizedString.nowPlaying // For some reason, `UITableViewCell.accessibilityLabel == nil` at this point.
		} else {
			speakerImageView.image = UIImage(systemName: .SFSpeakerNoWave)
			accessibilityValue = LocalizedString.paused
		}
	}
}
