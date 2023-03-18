//
//  AvatarDisplaying.swift
//  LavaRock
//
//  Created by h on 2020-11-07.
//

import UIKit

@MainActor
protocol AvatarDisplaying: AnyObject {
	// Adopting types must …
	// • Call `indicate` whenever appropriate.
	
	func indicate(avatarStatus: AvatarStatus)
}
