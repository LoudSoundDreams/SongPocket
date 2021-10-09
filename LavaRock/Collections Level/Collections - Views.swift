//
//  Collections - Views.swift
//  LavaRock
//
//  Created by h on 2020-11-06.
//

import UIKit
import CoreData

final class AllCollectionsCell: UITableViewCell {
	@IBOutlet var allLabel: UILabel!
}

final class CollectionCell: UITableViewCell {
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var nowPlayingIndicatorImageView: UIImageView!
	
	final func configure(
		with collection: Collection,
		isMovingAlbumsFromCollectionWith idOfSourceCollection: NSManagedObjectID?,
		renameFocusedCollectionAction: UIAccessibilityCustomAction
	) {
		// Title
		let collectionTitle = collection.title
		
		titleLabel.text = collectionTitle
		
		if let idOfSourceCollection = idOfSourceCollection {
			// This cell is appearing in "moving Albums" mode.
			if idOfSourceCollection == collection.objectID {
				titleLabel.textColor = UIColor.placeholderText // A proper way to make cells look disabled would be better. This is slightly different from the old cell.textLabel.isEnabled = false.
				disableWithAccessibilityTrait()
			} else {
				titleLabel.textColor = UIColor.label
				enableWithAccessibilityTrait()
			}
			accessibilityCustomActions = []
		} else {
			titleLabel.textColor = UIColor.label
			enableWithAccessibilityTrait()
			
			accessibilityCustomActions = [renameFocusedCollectionAction]
		}
	}
}

extension CollectionCell: NowPlayingIndicating {
}
