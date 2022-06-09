//
//  Sequence.swift
//  LavaRock
//
//  Created by h on 2022-06-08.
//

extension Sequence
where Element == String?
{
	func compactedAndFormattedAsNarrowList() -> String {
		return self
			.compactMap { $0 }
			.formatted(.list(type: .and, width: .narrow))
	}
}
