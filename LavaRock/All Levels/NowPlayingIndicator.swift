//
//  NowPlayingIndicator.swift
//  LavaRock
//
//  Created by h on 2020-11-07.
//

import UIKit

struct NowPlayingIndicator {
	let image: UIImage?
	let accessibilityLabel: String?
	
	init(
		isInPlayer: Bool,
		isPlaying: Bool // MPMusicPlaybackState has more cases than just .playing and .paused. Call this with isPlaying: true if and only if player controller is playing. Otherwise, call this with isPlaying: false to get the "in player, but paused" indicator.
	) {
		guard isInPlayer else {
			image = nil
			accessibilityLabel = nil
			return
		}
		
		if isPlaying {
			if #available(iOS 14, *) {
				image = UIImage(systemName: "speaker.wave.2.fill")
			} else { // iOS 13
				image = UIImage(systemName: "speaker.2.fill")
			}
			accessibilityLabel = LocalizedString.nowPlaying
		} else {
			image = UIImage(systemName: "speaker.fill")
			accessibilityLabel = LocalizedString.paused
		}
	}
}

protocol NowPlayingIndicatorDisplayer {
	var nowPlayingIndicatorImageView: UIImageView! { get set }
//	var accessibilityLabel: String? { get set }
	var accessibilityValue: String? { get set }
	
	mutating func apply(
		_ indicator: NowPlayingIndicator
	)
}

extension NowPlayingIndicatorDisplayer {
	
	mutating func apply(
		_ indicator: NowPlayingIndicator
	) {
		nowPlayingIndicatorImageView.image = indicator.image
		accessibilityValue = indicator.accessibilityLabel
	}
	
}

protocol NowPlayingIndicatorManager {
	func refreshNowPlayingIndicators(
		isInPlayerDeterminer: (IndexPath) -> Bool
	)
	func isInPlayer(libraryItemFor indexPath: IndexPath) -> Bool
}
