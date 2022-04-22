//
//  Weak.swift
//  LavaRock
//
//  Created by h on 2022-02-26.
//

final class Weak<Referencee: AnyObject> {
	weak var referencee: Referencee? = nil
	init(_ referencee: Referencee) { self.referencee = referencee }
}
