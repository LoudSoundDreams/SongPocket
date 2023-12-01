//
//  Constants.swift
//  LavaRock
//
//  Created by h on 2022-06-27.
//

import SwiftUI
enum LRColor {
	static let grey_oneEighth = Color(
		hue: 0,
		saturation: 0,
		brightness: 1/8
	)
}

extension Double {
	static var oneEighth: Self { 1/8 }
	static var oneFourth: Self { 1/4 }
	static var oneHalf: Self { 1/2 }
}
extension Float {
	static var oneFourth: Self { 1/4 }
}
extension CGFloat {
	static var oneEighth: Self { 1/8 }
	static var oneHalf: Self { 1/2 }
	static var eight: Self { 8 }
}
