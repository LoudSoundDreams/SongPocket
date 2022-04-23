//
//  GroupIndex, ItemIndex.swift
//  LavaRock
//
//  Created by h on 2022-04-22.
//

struct GroupIndex {
	let __: Int
	
	init(_ value: Int) {
		self.__ = value
	}
}

struct ItemIndex {
	let __: Int
	
	init(_ value: Int) {
		self.__ = value
	}
}
extension ItemIndex: Comparable {
	static func < (lhs: Self, rhs: Self) -> Bool {
		return lhs.__ < rhs.__
	}
}
