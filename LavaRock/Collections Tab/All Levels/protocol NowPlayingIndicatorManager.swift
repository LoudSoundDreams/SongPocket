//
//  protocol NowPlayingIndicatorManager.swift
//  LavaRock
//
//  Created by h on 2020-11-06.
//

import UIKit

protocol NowPlayingIndicatorManager {
	func nowPlayingIndicator(forRowAt indexPath: IndexPath) -> (UIImage?, String?)
}
