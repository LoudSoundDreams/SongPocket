//
//  protocol LibraryItem.swift
//  LavaRock
//
//  Created by h on 2021-04-09.
//

import CoreData

protocol LibraryItem {
	var index: Int64 { get set }
}

extension Array {
	
	mutating func reindex() where Element: LibraryItem {
		for index in 0 ..< count {
			self[index].index = Int64(index)
		}
	}
	
}

protocol LibraryContainer {
	var contents: NSSet? { get set }
}

extension LibraryContainer {
	
	func isEmpty() -> Bool {
		return contents == nil || contents?.count == 0
	}
	
}
