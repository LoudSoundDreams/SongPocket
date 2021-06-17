//
//  protocol NowPlayingIndicator.swift
//  LavaRock
//
//  Created by h on 2020-11-07.
//

import UIKit

protocol NowPlayingIndicatorManager {
	func refreshNowPlayingIndicators(
		isInPlayerDeterminer: (IndexPath) -> Bool
	)
	func isInPlayer(libraryItemFor indexPath: IndexPath) -> Bool
}

protocol NowPlayingIndicator {
	var nowPlayingIndicatorImageView: UIImageView! { get set }
	var accessibilityValue: String? { get set }
	var accessibilityLabel: String? { get set }
	
	mutating func applyNowPlayingIndicator(
		_ nowPlayingIndicator: (UIImage?, String?)
	)
}

extension NowPlayingIndicator {
	
	mutating func applyNowPlayingIndicator(
		_ nowPlayingIndicator: (UIImage?, String?)
	) {
		nowPlayingIndicatorImageView.image = nowPlayingIndicator.0
		accessibilityValue = nowPlayingIndicator.1
	}
	
}
