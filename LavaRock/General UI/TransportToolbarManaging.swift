//
//  TransportToolbarManaging.swift
//  LavaRock
//
//  Created by h on 2022-02-02.
//

import UIKit
import MediaPlayer

@MainActor
protocol TransportToolbarManaging: UIViewController {
	// Adopting types must …
	// • Respond to `LRModifiedReel` `Notification`s and call `freshenTransportToolbar`.
	
	// Adopting types might want to …
	// • Override `accessibilityPerformMagicTap` and toggle playback.
	// However, as of iOS 15.4 developer beta 4, if no responder between the VoiceOver-focused element and the app delegate implements `accessibilityPerformMagicTap`, then VoiceOver toggles audio playback. https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/SupportingAccessibility.html
	
	var previousSongButton: UIBarButtonItem { get }
	var rewindButton: UIBarButtonItem { get }
	var jumpBackwardButton: UIBarButtonItem { get }
	var playPauseButton: UIBarButtonItem { get }
	var jumpForwardButton: UIBarButtonItem { get }
	var nextSongButton: UIBarButtonItem { get }
	var moreButton: UIBarButtonItem { get }
	var moreVC: UIViewController { get }
}
extension TransportToolbarManaging {
	private var player: MPMusicPlayerController? { TapeDeck.shared.player }
	
	var transportButtons: [UIBarButtonItem] {
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
	
	func makeMoreButton() -> UIBarButtonItem {
		return UIBarButtonItem(
			title: LocalizedString.more,
			primaryAction: UIAction { [weak self] _ in
				guard let self = self else { return }
				self.present(self.moreVC, animated: true)
			})
	}
	func makeMoreVC() -> UIViewController {
		return UIStoryboard(name: "Console", bundle: nil)
			.instantiateInitialViewController()!
	}
	
	func makePreviousSongButton() -> UIBarButtonItem {
		let button = UIBarButtonItem(
			title: LocalizedString.previousTrack,
			image: Enabling.console
			? UIImage(systemName: "arrow.backward.circle")
			: UIImage(systemName: "backward.end"),
			primaryAction: UIAction { [weak self] _ in
				self?.player?.skipToPreviousItem()
			})
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}
	
	func makeRewindButton() -> UIBarButtonItem {
		let button = UIBarButtonItem(
			title: LocalizedString.restart,
			image: UIImage(systemName: "arrow.counterclockwise.circle"),
			primaryAction: UIAction { [weak self] _ in
				self?.player?.skipToBeginning()
			})
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}
	
	func makeJumpBackwardButton() -> UIBarButtonItem {
		let button = UIBarButtonItem(
			title: LocalizedString.skip10SecondsBackwards,
			image: UIImage(systemName: "gobackward.15"),
			primaryAction: UIAction { [weak self] _ in
				self?.player?.currentPlaybackTime -= 15
			})
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}
	
	func makeJumpForwardButton() -> UIBarButtonItem {
		let button = UIBarButtonItem(
			title: LocalizedString.skip10SecondsForward,
			image: UIImage(systemName: "goforward.15"),
			primaryAction: UIAction { [weak self] _ in
				self?.player?.currentPlaybackTime += 15
			})
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}
	
	func makeNextSongButton() -> UIBarButtonItem {
		let button = UIBarButtonItem(
			title: LocalizedString.nextTrack,
			image: Enabling.console
			? UIImage(systemName: "arrow.forward.circle")
			: UIImage(systemName: "forward.end"),
			primaryAction: UIAction { [weak self] _ in
				self?.player?.skipToNextItem()
			})
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}
	
	private static var moreDefaultImage: UIImage { UIImage(systemName: "line.3.horizontal.circle")! }
	func freshenTransportToolbar() {
		
		func configurePlayButton() {
			playPauseButton.title = LocalizedString.play
			playPauseButton.primaryAction = UIAction(
				image: UIImage(systemName: "play.circle")
			) { [weak self] _ in
				self?.player?.play()
			}
			// As of iOS 15.3 developer beta 1, even when you set `UIBarButtonItem.width` manually, the “pause.fill” button is still narrower than the “play.fill” button.
			playPauseButton.accessibilityTraits.formUnion(.startsMediaSession)
		}
		
		guard
			let player = player,
			!(Enabling.console && Reel.mediaItems.isEmpty)
		else {
			configurePlayButton()
			transportButtons.forEach { $0.disableWithAccessibilityTrait() }
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
			) { [weak self] _ in
				self?.player?.pause()
			}
			playPauseButton.accessibilityTraits.subtract(.startsMediaSession)
		} else {
			configurePlayButton()
		}
		
		// Enable or disable each button as appropriate
		transportButtons.forEach { $0.enableWithAccessibilityTrait() }
		if player.indexOfNowPlayingItem == 0 {
			previousSongButton.disableWithAccessibilityTrait()
		}
	}
}
