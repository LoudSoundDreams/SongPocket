//
//  AvatarDisplaying.swift
//  LavaRock
//
//  Created by h on 2020-11-07.
//

import UIKit

@MainActor
protocol AvatarDisplaying__: AnyObject {
	// Adopting types must…
	// • Call `indicateAvatarStatus__` whenever appropriate.
	
	func indicateAvatarStatus__(_ avatarStatus: AvatarStatus)
}
