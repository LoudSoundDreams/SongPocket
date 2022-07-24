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
	
	private let moreButton: UIBarButtonItem
	
	private lazy var previousButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			title: LRString.previousTrack,
			image: UIImage(systemName: "arrow.backward.circle"),
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
			title: LRString.nextTrack,
			image: UIImage(systemName: "arrow.forward.circle"),
			primaryAction: UIAction { _ in
				Self.player?.skipToNextItem()
			})
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	
	private lazy var openMusicButton: UIBarButtonItem = {
		return UIBarButtonItem(
			title: LRString.openMusic,
			image: UIImage(systemName: "arrow.up.forward.app"),
			primaryAction: UIAction(handler: { action in
				UIApplication.shared.open(.music)
			}))
	}()
	
	var buttons_array: [UIBarButtonItem] {
		if Enabling.console {
			return [
				moreButton,
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
				openMusicButton,
			]
		}
	}
	
	init(
		moreButtonAction: UIAction
	) {
		moreButton = UIBarButtonItem(
			title: LRString.more,
			primaryAction: moreButtonAction)
		
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
	
	private static let moreButtonDefaultImage = UIImage(systemName: "chevron.up.circle")!
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
			!(Enabling.console && Reel.mediaItems.isEmpty)
		else {
			configurePlayButton()
			
			moreButton.image = Self.moreButtonDefaultImage
			
			// Enable or disable each button as appropriate
			buttons_array.forEach {
				$0.disableWithAccessibilityTrait()
			}
			openMusicButton.enableWithAccessibilityTrait()
			moreButton.enableWithAccessibilityTrait()
			return
		}
		
		moreButton.image = {
			switch player.repeatMode {
			case .default:
				return Self.moreButtonDefaultImage
			case .none:
				return Self.moreButtonDefaultImage
			case .one:
				return UIImage(systemName: "repeat.1.circle.fill")!
			case .all:
				return UIImage(systemName: "repeat.circle.fill")!
			@unknown default:
				return Self.moreButtonDefaultImage
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
