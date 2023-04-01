//
//  UIViewController.swift
//  LavaRock
//
//  Created by h on 2022-01-27.
//

import UIKit

extension UIViewController {
	final func present__async(
		_ toPresent: UIViewController,
		animated: Bool
	) async {
		await withCheckedContinuation { continuation in
			present(toPresent, animated: animated) {
				continuation.resume()
			}
		}
	}
	
	final func dismiss__async(
		animated: Bool
	) async {
		await withCheckedContinuation { continuation in
			dismiss(animated: animated) {
				continuation.resume()
			}
		}
	}
}
