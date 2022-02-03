//
//  TabBarController.swift
//  LavaRock
//
//  Created by h on 2021-10-22.
//

import UIKit

final class TabBarController: UITabBarController {
	final override func accessibilityPerformMagicTap() -> Bool {
		return false // As of iOS 15.4 developer beta 4, if no responder between the VoiceOver-focused element and the app delegate implements `accessibilityPerformMagicTap`, then VoiceOver toggles playback in the built-in Music app. https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/SupportingAccessibility.html
	}
}
