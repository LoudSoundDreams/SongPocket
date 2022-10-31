//
//  MainToolbar.swift
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
final class MainToolbar {
	private static var player: MPMusicPlayerController? { TapeDeck.shared.player }
	
	private let showConsoleButton: UIBarButtonItem
	
	private lazy var previousButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			title: LRString.previous,
			image: {
				if Enabling.inAppPlayer {
					return UIImage(systemName: "backward.end.circle")
				} else {
					return UIImage(systemName: "arrow.backward.circle")
				}
			}(),
			primaryAction: UIAction { _ in
				Self.player?.skipToPreviousItem()
			})
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	
	private lazy var rewindButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			title: LRString.restart,
			image: UIImage(systemName: "arrow.counterclockwise.circle"),
			primaryAction: UIAction { _ in
				Self.player?.skipToBeginning()
			})
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	
	private lazy var skipBackButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			title: LRString.skip10SecondsBackwards,
			image: UIImage(systemName: "gobackward.15"),
			primaryAction: UIAction { _ in
				Self.player?.currentPlaybackTime -= 15
			})
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	
	private lazy var playPauseButton = UIBarButtonItem()
	
	private lazy var skipForwardButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			title: LRString.skip10SecondsForward,
			image: UIImage(systemName: "goforward.15"),
			primaryAction: UIAction { _ in
				Self.player?.currentPlaybackTime += 15
			})
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	
	private lazy var nextButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			title: LRString.next,
			image: {
				if Enabling.inAppPlayer {
					return UIImage(systemName: "forward.end.circle")
				} else {
					return UIImage(systemName: "arrow.forward.circle")
				}
			}(),
			primaryAction: UIAction { _ in
				Self.player?.skipToNextItem()
			})
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	
	private let open_Music_button: UIBarButtonItem = .make_open_Music()
	
	var buttons_array: [UIBarButtonItem] {
		if Enabling.inAppPlayer {
			return [
				showConsoleButton,
				.flexibleSpace(),
				skipBackButton,
				.flexibleSpace(),
				playPauseButton,
				.flexibleSpace(),
				skipForwardButton,
				.flexibleSpace(),
				nextButton,
			]
		} else {
			return [
				previousButton,
				.flexibleSpace(),
				rewindButton,
				.flexibleSpace(),
				playPauseButton,
				.flexibleSpace(),
				nextButton,
				.flexibleSpace(),
				open_Music_button,
			]
		}
	}
	
	init(
		showConsoleAction: UIAction
	) {
		showConsoleButton = UIBarButtonItem(
			title: LRString.more,
			primaryAction: showConsoleAction)
		
		freshen()
		TapeDeck.shared.addReflector(weakly: self)
		
		NotificationCenter.default.addObserverOnce(
			self,
			selector: #selector(userChangedReelEmptiness),
			name: .userChangedReelEmptiness,
			object: nil)
	}
	@objc private func userChangedReelEmptiness() {
		freshen()
	}
	
//	private static let showConsoleButtonDefaultImage = UIImage(systemName: "line.3.horizontal.circle")!
	private static let showConsoleButtonDefaultImage = UIImage(systemName: "chevron.up.circle")!
	private func freshen() {
		
		func configurePlayButton() {
			playPauseButton.title = LRString.play
			playPauseButton.primaryAction = UIAction(
				image: UIImage(systemName: "play.circle")
			) { _ in
				Self.player?.play()
			}
			playPauseButton.accessibilityTraits.formUnion(.startsMediaSession)
		}
		
		guard
			let player = Self.player,
			!(Enabling.inAppPlayer && Reel.mediaItems.isEmpty)
		else {
			configurePlayButton()
			
			showConsoleButton.image = Self.showConsoleButtonDefaultImage
			
			// Enable or disable each button as appropriate
			buttons_array.forEach {
				$0.disableWithAccessibilityTrait()
			}
			open_Music_button.enableWithAccessibilityTrait()
			showConsoleButton.enableWithAccessibilityTrait()
			return
		}
		
		showConsoleButton.image = {
			switch player.repeatMode {
			case .default:
				return Self.showConsoleButtonDefaultImage
			case .none:
				return Self.showConsoleButtonDefaultImage
			case .one:
				return UIImage(systemName: "repeat.1.circle.fill")!
			case .all:
				return UIImage(systemName: "repeat.circle.fill")!
			@unknown default:
				return Self.showConsoleButtonDefaultImage
			}
		}()
		
		if player.playbackState == .playing {
			// Configure “pause” button
			playPauseButton.title = LRString.pause
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
		buttons_array.forEach {
			$0.enableWithAccessibilityTrait()
		}
	}
}
extension MainToolbar: TapeDeckReflecting {
	func reflect_playback_mode() {
		freshen()
	}
	
	func reflect_now_playing_item() {
		freshen()
	}
}
