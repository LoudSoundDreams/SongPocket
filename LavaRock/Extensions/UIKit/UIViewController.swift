//
//  UIViewController.swift
//  LavaRock
//
//  Created by h on 2022-01-27.
//

import UIKit

extension UIViewController {
	// TO DO: Do we need `@MainActor` on this?
	final func dismiss_async(
		animated: Bool
	) async {
		await withCheckedContinuation { continuation in
			dismiss(animated: animated) {
				continuation.resume()
			}
		}
	}
}
