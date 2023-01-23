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
			rootViewController: UIStoryboard(name: "OptionsTVC", bundle: nil)
				.instantiateInitialViewController()!
		)
		
		did_init()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		did_init()
	}
	
	private func did_init() {
	}
}
