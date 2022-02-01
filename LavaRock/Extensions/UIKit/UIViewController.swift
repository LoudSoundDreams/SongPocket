//
//  UIViewController.swift
//  LavaRock
//
//  Created by h on 2022-01-27.
//

import UIKit

extension UIViewController {
//	final func present_async(
//		_ viewControllerToPresent: UIViewController,
//		animated: Bool
//	) async {
//		await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
//			present(viewControllerToPresent, animated: animated) { // “Modifications to the layout engine must not be performed from a background thread after it has been accessed from the main thread.” / “UIViewController.present(_:animated:completion:) must be used from main thread only”
//				continuation.resume()
//			}
//		}
//	}
	
	final func dismiss_async(
		animated: Bool
	) async {
		await withCheckedContinuation { continuation in
			dismiss(animated: animated) {
//				Task { await MainActor.run { // This might be necessary. https://www.swiftbysundell.com/articles/the-main-actor-attribute/
				continuation.resume()
//				}}
			}
		}
	}
}
