//
//  Sequence.swift
//  LavaRock
//
//  Created by h on 2022-06-08.
//

extension Sequence {
	func compacted<WrappedType>() -> [WrappedType]
	where Element == Optional<WrappedType>
	{
		return compactMap { $0 }
	}
	
	func compactedAndFormattedAsNarrowList() -> String
	where Element == String?
	{
		return self
			.compacted()
			.formatted(.list(type: .and, width: .narrow))
	}
}
