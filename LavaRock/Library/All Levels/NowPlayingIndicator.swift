//
//  NowPlayingIndicator.swift
//  LavaRock
//
//  Created by h on 2020-11-07.
//

import UIKit

protocol NowPlayingIndicating {
	var nowPlayingIndicatorImageView: UIImageView! { get set }
//	var accessibilityLabel: String? { get set }
	var accessibilityValue: String? { get set }
	
	mutating func applyNowPlayingIndicator(_ indicator: NowPlayingIndicator)
}

extension NowPlayingIndicating {
	mutating func applyNowPlayingIndicator(_ indicator: NowPlayingIndicator) {
		nowPlayingIndicatorImageView.image = indicator.image
		accessibilityValue = indicator.accessibilityLabel // For some reason, UITableViewCell.accessibilityLabel is nil at this point.
	}
}

protocol NowPlayingDetermining {
	func isInPlayer(anyIndexPath: IndexPath) -> Bool
}

struct NowPlayingIndicator {
	let image: UIImage?
	let accessibilityLabel: String?
	
	init(
		isInPlayer: Bool,
		isPlaying: Bool // MPMusicPlayerController.playbackState has more cases than just .playing and .paused. Call this with isPlaying: true if and only if the player is playing. Otherwise, call this with isPlaying: false to get the "in player, but paused" indicator.
	) {
		guard isInPlayer else {
			image = nil
			accessibilityLabel = nil
			return
		}
		if isPlaying {
			image = .waveSpeakerSymbol
			accessibilityLabel = LocalizedString.nowPlaying
		} else {
			image = .noWaveSpeakerSymbol
			accessibilityLabel = LocalizedString.paused
		}
	}
}
