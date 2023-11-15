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
	static func song(with musicItemID: MusicItemID) async -> MusicKit.Song?
	where MusicItemType == MusicKit.Song
	{
		var request = MusicLibraryRequest()
		request.filter(matching: \.id, equalTo: musicItemID)
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
