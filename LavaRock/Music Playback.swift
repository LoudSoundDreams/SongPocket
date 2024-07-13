// 2022-03-19

@preconcurrency import MusicKit

extension SystemMusicPlayer {
	@MainActor static var _shared: SystemMusicPlayer? {
		guard MusicAuthorization.currentStatus == .authorized else { return nil }
		return .shared
	}
}

import MediaPlayer
extension MPMusicPlayerController {
	static var _system: MPMusicPlayerController? {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return nil }
		return .systemMusicPlayer
	}
}

extension Song {
	@MainActor final func playAlbumStartingHere() async {
		guard
			let player = SystemMusicPlayer._shared,
			let rowItem = await musicKitSong(),
			let songsInAlbum = container?.songs(sorted: true)
		else { return }
		let musicItems: [MusicKit.Song] = await {
			var result: [MusicKit.Song] = []
			for song in songsInAlbum {
				guard let musicItem = await song.musicKitSong() else { continue }
				result.append(musicItem)
			}
			return result
		}()
		
		player.queue = SystemMusicPlayer.Queue(for: musicItems, startingAt: rowItem)
		try? await player.play()
		
		// As of iOS 17.2 beta, if setting the queue did effectively nothing, you must do these after calling `play`, not before.
		player.state.repeatMode = MusicPlayer.RepeatMode.none
		player.state.shuffleMode = .off
	}
	@MainActor final func play() async {
		guard
			let player = SystemMusicPlayer._shared,
			let musicItem = await musicKitSong()
		else { return }
		
		player.queue = SystemMusicPlayer.Queue(for: [musicItem])
		try? await player.play()
		
		player.state.repeatMode = MusicPlayer.RepeatMode.none
		player.state.shuffleMode = .off
	}
	@MainActor final func playLast() async {
		guard
			let player = SystemMusicPlayer._shared,
			let musicItem = await musicKitSong()
		else { return }
		
		guard let _ =
				try? await player.queue.insert([musicItem], position: .tail)
		else { return }
		
		UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
	}
	@MainActor final func playRestOfAlbumLast() async {
		guard
			let player = SystemMusicPlayer._shared,
			let rowItem = await musicKitSong(),
			let songsInAlbum = container?.songs(sorted: true)
		else { return }
		let toAppend: [MusicKit.Song] = await {
			var musicItems: [MusicKit.Song] = []
			for song in songsInAlbum {
				guard let musicItem = await song.musicKitSong() else { continue }
				musicItems.append(musicItem)
			}
			let result = musicItems.drop(while: { $0.id != rowItem.id })
			return Array(result)
		}()
		
		guard let _ =
				try? await player.queue.insert(toAppend, position: .tail)
		else { return }
		
		let impactor = UIImpactFeedbackGenerator(style: .heavy)
		impactor.impactOccurred()
		try? await Task.sleep(nanoseconds: 0_200_000_000)
		
		impactor.impactOccurred()
	}
	
	@MainActor final func musicKitSong() async -> MusicKit.Song? {
		var request = MusicLibraryRequest<MusicKit.Song>()
		request.filter(matching: \.id, equalTo: MusicItemID(String(persistentID)))
		guard
			let response = try? await request.response(),
			response.items.count == 1
		else { return nil }
		return response.items.first
	}
}
