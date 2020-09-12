//
//  Notifications - CollectionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-09-10.
//

import UIKit

extension CollectionsTVC {
	
	override func refreshDataAndViews() {
		if let albumMoverClipboard = albumMoverClipboard {
			if albumMoverClipboard.isMakingNewCollection {
				dismiss(animated: true, completion: nil)
				albumMoverClipboard.isMakingNewCollection = false
			}
			dismiss(animated: true, completion: nil)
			return
		} else if isRenamingCollection {
			dismiss(animated: true, completion: nil)
			isRenamingCollection = false
		}
		
		super.refreshDataAndViews()
	}
	
}
