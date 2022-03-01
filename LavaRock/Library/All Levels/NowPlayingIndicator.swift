//
//  NowPlayingIndicator.swift
//  LavaRock
//
//  Created by h on 2020-11-07.
//

import UIKit

protocol NowPlayingIndicating {
	var spacerSpeakerImageView: UIImageView! { get set }
	var speakerImageView: UIImageView! { get set }
	var accessibilityValue: String? { get set }
}

extension NowPlayingIndicating {
	mutating func applyNowPlayingIndicator(_ indicator: NowPlayingIndicator) {
		spacerSpeakerImageView.maximumContentSizeCategory = .extraExtraExtraLarge
		speakerImageView.maximumContentSizeCategory = .extraExtraExtraLarge
		
		speakerImageView.image = indicator.image
		accessibilityValue = indicator.accessibilityLabel // For some reason, `UITableViewCell.accessibilityLabel` is `nil` at this point.
	}
}

@MainActor
protocol NowPlayingDetermining {
	func isInPlayer(anyIndexPath: IndexPath) -> Bool
}

struct NowPlayingIndicator {
	let image: UIImage?
	let accessibilityLabel: String?
	
	init(
		isInPlayer: Bool,
		isPlaying: Bool
	) {
		guard isInPlayer else {
			image = nil
			accessibilityLabel = nil
			return
		}
		if isPlaying {
			image = UIImage(systemName: .SFSpeakerWave)
			accessibilityLabel = LocalizedString.nowPlaying
		} else {
			image = UIImage(systemName: .SFSpeakerNoWave)
			accessibilityLabel = LocalizedString.paused
		}
	}
}
