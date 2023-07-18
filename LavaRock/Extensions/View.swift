//
//  View.swift
//  LavaRock
//
//  Created by h on 2023-03-14.
//

import SwiftUI

extension View {
	func backgroundColorRandom() -> some View {
		background {
			Color(
				hue: Double.random(in: 0...1),
				saturation: Double.random(in: 0...1),
				brightness: 0.5)
		}
	}
}
