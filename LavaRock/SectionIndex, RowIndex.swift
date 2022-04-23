//
//  SectionIndex, RowIndex.swift
//  LavaRock
//
//  Created by h on 2022-04-22.
//

import Foundation

struct SectionIndex {
	let value: Int
	
	init(_ value: Int) {
		self.value = value
	}
}
extension SectionIndex: Hashable {}

struct RowIndex {
	let value: Int
	
	init(_ value: Int) {
		self.value = value
	}
}
extension RowIndex: Comparable {
	static func < (lhs: Self, rhs: Self) -> Bool {
		return lhs.value < rhs.value
	}
}

extension IndexPath {
	var sectionIndex: SectionIndex {
		return SectionIndex(section)
	}
	var rowIndex: RowIndex {
		return RowIndex(row)
	}
	
	init(_ rowIndex: RowIndex, in sectionIndex: SectionIndex) {
		self.init(row: rowIndex.value, section: sectionIndex.value)
	}
}
