//
//  LibraryNC.swift
//  LavaRock
//
//  Created by h on 2021-12-30.
//

import UIKit

final class LibraryNC: UINavigationController {
	init(rootStoryboardName: String) {
		super.init(
			rootViewController: UIStoryboard(name: rootStoryboardName, bundle: nil)
				.instantiateInitialViewController()!
		)
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}
}
