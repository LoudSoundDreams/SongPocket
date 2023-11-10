//
//  Player.swift
//  LavaRock
//
//  Created by h on 2022-03-19.
//

import MusicKit

@MainActor
extension SystemMusicPlayer {
	static var sharedIfAuthorized: SystemMusicPlayer? {
		guard MusicAuthorization.currentStatus == .authorized else {
			return nil
		}
		return .shared
	}
}

@MainActor
extension MusicLibraryRequest {
	static func filter(matchingMusicItemID: MusicItemID) async -> MusicKit.Song? {
		var request = MusicLibraryRequest<MusicKit.Song>()
		request.filter(matching: \.id, equalTo: matchingMusicItemID)
		guard
			let response = try? await request.response(),
			response.items.count == 1
		else {
			return nil
		}
		
		return response.items.first
	}
}

import MediaPlayer

extension MPMusicPlayerController {
	static var systemMusicPlayerIfAuthorized: MPMusicPlayerController? {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return nil
		}
		return .systemMusicPlayer
	}
}
