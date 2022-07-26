//
//  OptionsNC.swift
//  LavaRock
//
//  Created by h on 2022-04-22.
//

import UIKit

final class OptionsNC: UINavigationController {
	init() {
		super.init(
			rootViewController: UIStoryboard(name: "Options", bundle: nil)
				.instantiateInitialViewController()!
		)
		
		setUp()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		setUp()
	}
	
	private func setUp() {
	}
}
