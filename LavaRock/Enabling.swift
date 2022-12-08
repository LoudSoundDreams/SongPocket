//
//  Enabling.swift
//  LavaRock
//
//  Created by h on 2021-10-29.
//

enum Enabling {
	static let sim_emptyLibrary = 10 == 1
	
	static let inAppPlayer = 10 == 1
	static let swiftUI__console = inAppPlayer && 10 == 1
	
	static let swiftUI__options = 10 == 1
}

#if targetEnvironment(simulator)
enum Global {
	static var songID: SongID? = nil
}
#endif
