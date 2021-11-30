//
//  Print.swift
//  LavaRock
//
//  Created by h on 2021-11-10.
//

struct Print {
	@discardableResult init(_ content: Any?) {
		print(String(describing: content))
	}
}
