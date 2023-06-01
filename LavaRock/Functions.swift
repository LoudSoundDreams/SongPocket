//
//  Functions.swift
//  LavaRock
//
//  Created by h on 2023-06-01.
//

import UIKit

enum Fn {
	static func reversed(
		_ groupedMenuElements: [[UIMenuElement]]
	) -> [[UIMenuElement]] {
		var result = groupedMenuElements
		result.reverse()
		result.indices.forEach {
			result[$0].reverse()
		}
		return result
	}
}
