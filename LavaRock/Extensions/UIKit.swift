//
//  UIKit.swift
//  LavaRock
//
//  Created by h on 2022-01-27.
//

import UIKit

extension UIViewController {
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

extension UIImpactFeedbackGenerator {
	final func impactOccurredTwice() {
		Task {
			impactOccurred()
			try await Task.sleep(nanoseconds: 0_200_000_000)
			
			impactOccurred()
		}
	}
}
