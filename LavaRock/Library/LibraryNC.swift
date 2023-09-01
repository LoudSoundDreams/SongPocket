//
//  LibraryNC.swift
//  LavaRock
//
//  Created by h on 2021-12-30.
//

import UIKit

final class LibraryNC: UINavigationController {
	lazy var mainToolbar = MainToolbar__UIKit()
	
	init(rootStoryboardName: String) {
		super.init(
			rootViewController: UIStoryboard(name: rootStoryboardName, bundle: nil)
				.instantiateInitialViewController()!
		)
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		toolbar.scrollEdgeAppearance = toolbar.standardAppearance
	}
}
