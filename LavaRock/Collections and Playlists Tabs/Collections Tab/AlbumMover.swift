//
//  AlbumMover.swift
//  LavaRock
//
//  Created by h on 2020-08-04.
//

import UIKit

protocol AlbumMover {
	var moveAlbumsClipboard: MoveAlbumsClipboard? { get set }
	var didMoveAlbumsToNewCollections: Bool { get set }
	
	func setNavigationItemPrompt()
}
