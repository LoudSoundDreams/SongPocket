//
//  protocol NowPlayingIndicator.swift
//  LavaRock
//
//  Created by h on 2020-11-07.
//

import UIKit

protocol NowPlayingIndicator {
	var nowPlayingIndicatorImageView: UIImageView! { get set }
	var accessibilityValue: String? { get set }
	
	mutating func apply(nowPlayingIndicator: (UIImage?, String?))
}

extension NowPlayingIndicator {
	
	mutating func apply(
		nowPlayingIndicator: (UIImage?, String?)
	) {
		nowPlayingIndicatorImageView.image = nowPlayingIndicator.0
		accessibilityValue = nowPlayingIndicator.1
	}
	
}
