//
//  TransportBar.swift
//  LavaRock
//
//  Created by h on 2022-05-09.
//

import UIKit
import MediaPlayer

// Instantiators might want to …
// • Implement `accessibilityPerformMagicTap` and toggle playback.
// However, as of iOS 15.4 developer beta 4, if no responder between the VoiceOver-focused element and the app delegate implements `accessibilityPerformMagicTap`, then VoiceOver toggles audio playback. https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/SupportingAccessibility.html
@MainActor
final class TransportBar {
	private static var player: MPMusicPlayerController? { TapeDeck.shared.player }
	
	private let moreButton: UIBarButtonItem
	
	private let previousSongButton: UIBarButtonItem
	private let rewindButton: UIBarButtonItem
	private let jumpBackwardButton: UIBarButtonItem
	private let playPauseButton = UIBarButtonItem()
	private let jumpForwardButton: UIBarButtonItem
	private let nextSongButton: UIBarButtonItem
	
	var buttons: [UIBarButtonItem] {
		if Enabling.console {
			return [
				moreButton, .flexibleSpace(),
				jumpBackwardButton, .flexibleSpace(),
				playPauseButton, .flexibleSpace(),
				jumpForwardButton, .flexibleSpace(),
				nextSongButton,
			]
		} else {
			return [
				previousSongButton, .flexibleSpace(),
				rewindButton, .flexibleSpace(),
				playPauseButton, .flexibleSpace(),
				nextSongButton,
			]
		}
	}
	
	init(
		moreButtonAction: UIAction
	) {
		moreButton = UIBarButtonItem(
			title: LocalizedString.more,
			primaryAction: moreButtonAction)
		
		previousSongButton = {
			let button = UIBarButtonItem(
				title: LocalizedString.previousTrack,
				image: Enabling.console
				? UIImage(systemName: "arrow.backward.circle")
				: UIImage(systemName: "backward.end"),
				primaryAction: UIAction { _ in
					Self.player?.skipToPreviousItem()
				})
			button.accessibilityTraits.formUnion(.startsMediaSession)
			return button
		}()
		rewindButton = {
			let button = UIBarButtonItem(
				title: LocalizedString.restart,
				image: UIImage(systemName: "arrow.counterclockwise.circle"),
				primaryAction: UIAction { _ in
					Self.player?.skipToBeginning()
				})
			button.accessibilityTraits.formUnion(.startsMediaSession)
			return button
		}()
		jumpBackwardButton = {
			let button = UIBarButtonItem(
				title: LocalizedString.skip10SecondsBackwards,
				image: UIImage(systemName: "gobackward.15"),
				primaryAction: UIAction { _ in
					Self.player?.currentPlaybackTime -= 15
				})
			button.accessibilityTraits.formUnion(.startsMediaSession)
			return button
		}()
		jumpForwardButton = {
			let button = UIBarButtonItem(
				title: LocalizedString.skip10SecondsForward,
				image: UIImage(systemName: "goforward.15"),
				primaryAction: UIAction { _ in
					Self.player?.currentPlaybackTime += 15
				})
			button.accessibilityTraits.formUnion(.startsMediaSession)
			return button
		}()
		nextSongButton = {
			let button = UIBarButtonItem(
				title: LocalizedString.nextTrack,
				image: Enabling.console
				? UIImage(systemName: "arrow.forward.circle")
				: UIImage(systemName: "forward.end"),
				primaryAction: UIAction { _ in
					Self.player?.skipToNextItem()
				})
			button.accessibilityTraits.formUnion(.startsMediaSession)
			return button
		}()
	}
	
	private static let moreDefaultImage = UIImage(systemName: "line.3.horizontal.circle")!
	final func freshen() {
		
		func configurePlayButton() {
			playPauseButton.title = LocalizedString.play
			playPauseButton.primaryAction = UIAction(
				image: UIImage(systemName: "play.circle")
			) { _ in
				Self.player?.play()
			}
			// As of iOS 15.3 developer beta 1, even when you set `UIBarButtonItem.width` manually, the “pause.fill” button is still narrower than the “play.fill” button.
			playPauseButton.accessibilityTraits.formUnion(.startsMediaSession)
		}
		
		guard
			let player = Self.player,
			!(Enabling.console && Reel.mediaItems.isEmpty)
		else {
			configurePlayButton()
			buttons.forEach { $0.disableWithAccessibilityTrait() }
			moreButton.image = Self.moreDefaultImage
			moreButton.enableWithAccessibilityTrait()
			return
		}
		
		moreButton.image = {
			switch player.repeatMode {
			case .default:
				return Self.moreDefaultImage
			case .none:
				return Self.moreDefaultImage
			case .one:
				return UIImage(systemName: "repeat.1.circle.fill")!
			case .all:
				return UIImage(systemName: "repeat.circle.fill")!
			@unknown default:
				return Self.moreDefaultImage
			}
		}()
		
		if player.playbackState == .playing {
			// Configure “pause” button
			playPauseButton.title = LocalizedString.pause
			playPauseButton.primaryAction = UIAction(
				image: UIImage(systemName: "pause.circle")
			) { _ in
				Self.player?.pause()
			}
			playPauseButton.accessibilityTraits.subtract(.startsMediaSession)
		} else {
			configurePlayButton()
		}
		
		// Enable or disable each button as appropriate
		buttons.forEach { $0.enableWithAccessibilityTrait() }
		if player.indexOfNowPlayingItem == 0 {
			previousSongButton.disableWithAccessibilityTrait()
		}
	}
}
