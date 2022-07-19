//
//  Section_I, Row_I.swift
//  LavaRock
//
//  Created by h on 2022-04-22.
//

import Foundation

struct Section_I {
	let value: Int
	
	init(_ value: Int) {
		self.value = value
	}
}
extension Section_I: Hashable {}

struct Row_I {
	let value: Int
	
	init(_ value: Int) {
		self.value = value
	}
}
extension Row_I: Comparable {
	static func < (lhs: Self, rhs: Self) -> Bool {
		return lhs.value < rhs.value
	}
}

extension IndexPath {
	var section_i: Section_I {
		return Section_I(section)
	}
	var row_i: Row_I {
		return Row_I(row)
	}
	
	init(_ row_i: Row_I, in section_i: Section_I) {
		self.init(row: row_i.value, section: section_i.value)
	}
}
