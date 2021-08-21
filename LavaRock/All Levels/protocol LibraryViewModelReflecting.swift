//
//  protocol LibraryViewModelReflecting.swift
//  LavaRock
//
//  Created by h on 2021-08-20.
//

import UIKit
import CoreData

protocol LibraryViewModelReflecting: AnyObject {
	var viewModel: LibraryViewModel { get set }
	var title: String? { get set }
}

extension LibraryViewModelReflecting {
	
	func reflectContainerTitles() {
		if let navigationItemTitle = viewModel.navigationItemTitleOptional() {
			title = navigationItemTitle
		}
	}
	
}

extension LibraryTVC: LibraryViewModelReflecting {
}
