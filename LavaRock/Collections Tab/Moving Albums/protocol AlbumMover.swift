//
//  protocol AlbumMover.swift
//  LavaRock
//
//  Created by h on 2020-08-04.
//

import UIKit
import CoreData

protocol AlbumMover {
	var albumMoverClipboard: AlbumMoverClipboard? { get set }
	
	func setAlbumMoverToolbar()
}

protocol AlbumMoverDelegate: AnyObject {
	func didAbort()
	func didMoveAlbums(didMakeNewCollection: Bool)
}
