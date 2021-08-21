//
//  LibraryTVC + LibraryViewModelReflecting.swift
//  LavaRock
//
//  Created by h on 2021-08-20.
//

import UIKit
import CoreData

extension LibraryTVC: LibraryViewModelReflecting {
	
	final func reflectContainerTitles(
		_ containerTitles: [String]
	) {
		guard let firstTitle = containerTitles.first else { return }
		if containerTitles.count == 1 {
			title = firstTitle
		}
	}
	
}
