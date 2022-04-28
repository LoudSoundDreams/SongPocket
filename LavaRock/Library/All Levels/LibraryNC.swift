//
//  LibraryNC.swift
//  LavaRock
//
//  Created by h on 2021-12-30.
//

import UIKit

final class LibraryNC: UINavigationController {
	// `MovesThemeToWindow`
	static var didMoveThemeToWindow = false
	
	final override func viewDidLoad() {
		super.viewDidLoad()
		
		if Enabling.opaqueTransportToolbar {
			if let toolbar = toolbar {
				toolbar.scrollEdgeAppearance = toolbar.standardAppearance
			}
		}
	}
	
	final override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		moveThemeToWindow()
	}
}
extension LibraryNC: MovesThemeToWindow {}
