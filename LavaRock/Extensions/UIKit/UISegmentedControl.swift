//
//  UISegmentedControl.swift
//  LavaRock
//
//  Created by h on 2022-03-21.
//

import UIKit

extension UISegmentedControl {
	final func disable() {
		setAllSegmentsEnabled(false)
	}
	
	final func enable() {
		setAllSegmentsEnabled(true)
	}
	
	private func setAllSegmentsEnabled(_ newState: Bool) {
		(0 ..< numberOfSegments).forEach { indexOfSegment in
			setEnabled(newState, forSegmentAt: indexOfSegment)
		}
	}
}
