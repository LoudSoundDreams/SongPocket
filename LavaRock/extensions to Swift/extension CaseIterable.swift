//
//  extension CaseIterable.swift
//  extension CaseIterable
//
//  Created by h on 2021-07-29.
//

extension CaseIterable {
	static func rawValues() -> [Self.RawValue]
	where Self: RawRepresentable
	{
		return allCases.map { $0.rawValue }
	}
}
