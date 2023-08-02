//
//  UIImpactFeedbackGenerator.swift
//  LavaRock
//
//  Created by h on 2022-12-10.
//

import UIKit

extension UIImpactFeedbackGenerator {
	final func impactOccurredTwice() {
		Task {
			impactOccurred()
			try await Task.sleep(nanoseconds: 0_200_000_000)
			
			impactOccurred()
		}
	}
}
