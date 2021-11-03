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

protocol LibraryContainer {
	var libraryTitle: String { get }
	var contents: NSSet? { get set }
}

extension LibraryContainer {
	
	func isEmpty() -> Bool {
		return contents == nil || contents?.count == 0
	}
	
}
