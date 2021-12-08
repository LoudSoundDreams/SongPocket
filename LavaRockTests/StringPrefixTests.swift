//
//  StringPrefixTests.swift
//  LavaRockTests
//
//  Created by h on 2021-12-10.
//

import XCTest
@testable import LavaRock

final class StringPrefixTests: XCTestCase {
	
	let johnWilliamsSpace = [
		"John Williams & London Symphony Orchestra",
		"John Williams ",
		"John Williams & Boston Pops Orchestra",
	]
	let johnWilliams = [
		"John Williams & London Symphony Orchestra",
		"John Williams",
		"John Williams ",
		"John Williams & Boston Pops Orchestra",
	]
	let johnSpace = [
		"John Williams & London Symphony Orchestra",
		"John Williams",
		"John Williams ",
		"John Williams & Boston Pops Orchestra",
		"John Smith",
	]
	let jo = [
		"John Williams & London Symphony Orchestra",
		"John Williams",
		"John Williams ",
		"John Williams & Boston Pops Orchestra",
		"Joe",
		"Jo",
		"John Smith",
	]
	let emptyString1 = [
		"John Williams & London Symphony Orchestra",
		"",
		"John Williams",
		"John Williams ",
		"John Williams & Boston Pops Orchestra",
	]
	let emptyString2 = [
		"John Williams & London Symphony Orchestra",
		" ",
		"John Williams",
		"John Williams ",
		"John Williams & Boston Pops Orchestra",
	]
	lazy var j
	= Array(repeating: johnSpace, count: 500).flatMap { $0 }
	+ ["J"]
	+ Array(repeating: johnSpace, count: 500).flatMap { $0 }
	lazy var emptyString3
	= Array(repeating: johnSpace, count: 500).flatMap { $0 }
	+ [" "]
	+ Array(repeating: johnSpace, count: 500).flatMap { $0 }
	
	lazy var arraysOfAlbumArtists = [
		johnWilliamsSpace,
		johnWilliams,
		johnSpace,
		jo,
		emptyString1,
		emptyString2,
		j,
		emptyString3,
	]
	
	func arraysCommonPrefixes() -> [String] {
		return arraysOfAlbumArtists.map { $0.commonPrefix() }
	}
	
	func testArrayCommonPrefix() {
		XCTAssertEqual(arraysCommonPrefixes(), [
			"John Williams ",
			"John Williams",
			"John ",
			"Jo",
			"",
			"",
			"J",
			"",
		])
	}
	
	func testSpeedArrayCommonPrefix() {
		measure {
			let _ = arraysCommonPrefixes()
		}
	}
	
	func testSpeedArrayCommonPrefixWithoutShortCircuit() {
		measure {
			let _ = j.commonPrefix()
		}
	}
	
	func testSpeedArrayCommonPrefixWithShortCircuit() {
		measure {
			let _ = emptyString3.commonPrefix()
		}
	}
	
	func trimmingWhitespaceAtEnd(ofEachIn strings: [String]) -> [String] {
		return strings.map { $0.trimmingWhitespaceAtEnd() }
	}
	
	func testStringTrimmingWhitespaceAtEnd() {
		let trimmed = trimmingWhitespaceAtEnd(ofEachIn: arraysCommonPrefixes())
		XCTAssertEqual(trimmed, [
			"John Williams",
			"John Williams",
			"John",
			"Jo",
			"",
			"",
			"J",
			"",
		])
	}
	
	func testSpeedTrimWhitespace() {
		let commonPrefixes = arraysCommonPrefixes()
		measure {
			let _ = trimmingWhitespaceAtEnd(ofEachIn: commonPrefixes)
		}
	}
	
}
