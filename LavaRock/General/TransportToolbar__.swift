//
//  TransportToolbar__.swift
//  LavaRock
//
//  Created by h on 2022-05-09.
//

import UIKit
import MediaPlayer

// As of iOS 15.4 developer beta 4, if no responder between the VoiceOver-focused element and the app delegate implements `accessibilityPerformMagicTap`, then VoiceOver toggles audio playback. https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/SupportingAccessibility.html
@MainActor
final class TransportToolbar__ {
	static let shared = TransportToolbar__()
	var barButtonItems: [UIBarButtonItem] {
		return [
			overflowButton, .flexibleSpace(),
			jumpBackButton, .flexibleSpace(),
			playPauseButton, .flexibleSpace(),
			jumpForwardButton, .flexibleSpace(),
			nextButton,
		]
	}
	
	// MARK: - PRIVATE
	
	private static var playerIfAuthorized: MPMusicPlayerController? { TapeDeck.shared.player }
	
	private lazy var overflowButton = UIBarButtonItem(
		title: LRString.more,
		image: Self.overflowButtonDefaultImage,
		menu: Self.newPlaybackMenu()
	)
	
	private lazy var jumpBackButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			title: LRString.skipBack15Seconds,
			image: UIImage(systemName: "gobackward.15"),
			primaryAction: UIAction { _ in
				Self.playerIfAuthorized?.currentPlaybackTime -= 15
			})
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	
	private lazy var playPauseButton = UIBarButtonItem()
	
	private lazy var jumpForwardButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			title: LRString.skipForward15Seconds,
			image: UIImage(systemName: "goforward.15"),
			primaryAction: UIAction { _ in
				Self.playerIfAuthorized?.currentPlaybackTime += 15
			})
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	
	private lazy var nextButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			title: LRString.next,
			image: UIImage(systemName: "forward.end.circle"),
			primaryAction: UIAction { _ in
				Self.playerIfAuthorized?.skipToNextItem()
			})
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	
	// MARK: - Overflow menu
	
	private static func newPlaybackMenu() -> UIMenu {
		let menuElements: [UIMenuElement] = [
			// Repeat
			UIMenu(
				options: .displayInline,
				children: [
					UIDeferredMenuElement.uncached({ useMenuElements in
						let action = UIAction(
							title: LRString.repeat_,
							image: UIImage(systemName: "repeat.1"),
							attributes: {
								if Self.playerIfAuthorized == nil {
									return .disabled
								}
								return []
							}(),
							state: {
								guard let player = Self.playerIfAuthorized else {
									return .off
								}
								if player.repeatMode == .one {
									return .on
								} else {
									return .off
								}
							}()
						) { _ in
							guard let player = Self.playerIfAuthorized else { return }
							if player.repeatMode == .one {
								player.repeatMode = .none
							} else {
								player.repeatMode = .one
							}
						}
						useMenuElements([action])
					}),
				]
			),
			
			// Transport
			UIMenu(
				options: .displayInline,
				children: [
					UIDeferredMenuElement.uncached({ useMenuElements in
						let action = UIAction(
							title: LRString.previous,
							image: UIImage(systemName: "backward.end.circle"),
							attributes: {
								var result: UIMenuElement.Attributes = [
									.keepsMenuPresented,
								]
								if Self.playerIfAuthorized == nil {
									result.formUnion(.disabled)
								}
								return result
							}()
						) { _ in
							Self.playerIfAuthorized?.skipToPreviousItem()
						}
						useMenuElements([action])
					}),
					
					UIDeferredMenuElement.uncached({ useMenuElements in
						let action = UIAction(
							title: LRString.restart,
							image: UIImage(systemName: "arrow.counterclockwise.circle"),
							attributes: {
								// I want to disable this when the playhead is already at start of track, but can’t reliably check that.
								if Self.playerIfAuthorized == nil {
									return .disabled
								}
								return []
							}()
						) { _ in
							Self.playerIfAuthorized?.skipToBeginning()
						}
						useMenuElements([action])
					}),
				].reversed()
			),
			
		]
		return UIMenu(children: menuElements.reversed())
	}
	
	// MARK: -
	
	private init() {
		reflect_playbackState_and_nowPlayingItem()
		TapeDeck.shared.addReflector(weakly: self)
	}
	
	private static let overflowButtonDefaultImage = UIImage(systemName: "ellipsis.circle")!
	private var hasRefreshenedOverflowButton = false
	private func reflect_playbackState_and_nowPlayingItem() {
#if targetEnvironment(simulator)
		defer {
			showPauseButton()
		}
#endif
		
		overflowButton.image = newOverflowButtonImage()
		
		guard
			let player = Self.playerIfAuthorized
				// Ideally, detect when no songs are in the player
		else {
			disableEverything()
			return
		}
		
		if player.playbackState == .playing {
			showPauseButton()
		} else {
			showPlayButton()
		}
		
		// Enable everything
		barButtonItems.forEach {
			$0.isEnabled = true
			$0.accessibilityTraits.subtract(.notEnabled)
		}
	}
	private func disableEverything() {
		showPlayButton()
		
		barButtonItems.forEach {
			$0.isEnabled = false
			$0.accessibilityTraits.formUnion(.notEnabled) // As of iOS 15.3 developer beta 1, setting `isEnabled` doesn’t do this automatically.
		}
		overflowButton.isEnabled = true
		overflowButton.accessibilityTraits.subtract(.notEnabled)
		return
	}
	private func newOverflowButtonImage() -> UIImage {
		guard let player = Self.playerIfAuthorized else {
			return Self.overflowButtonDefaultImage
		}
		switch player.repeatMode {
				// TO DO: Add accessibility labels or values when Repeat is on. What does the Photos app do with its overflow button when filtering to Shared Library?
			case .one: return UIImage(systemName: "repeat.1.circle.fill")!
			default:
				// As of iOS 16.2 developer beta 3, when the user first grants access to Music, Media Player can incorrectly return `.none` for 8ms or longer.
				// That happens even if the app crashes while the permission alert is visible, and we get first access on next launch.
				if !hasRefreshenedOverflowButton {
					hasRefreshenedOverflowButton = true
					
					Task {
						try? await Task.sleep(for: .milliseconds(50))
						
						overflowButton.image = newOverflowButtonImage()
					}
				}
				return Self.overflowButtonDefaultImage
		}
	}
	func showPlayButton() {
		playPauseButton.title = LRString.play
		playPauseButton.primaryAction = UIAction(
			image: UIImage(systemName: "play.circle")
		) { _ in
			Self.playerIfAuthorized?.play()
		}
		playPauseButton.accessibilityTraits.formUnion(.startsMediaSession)
	}
	func showPauseButton() {
		playPauseButton.title = LRString.pause
		playPauseButton.primaryAction = UIAction(
			image: UIImage(systemName: "pause.circle")
		) { _ in
			Self.playerIfAuthorized?.pause()
		}
		playPauseButton.accessibilityTraits.subtract(.startsMediaSession)
	}
}
extension TransportToolbar__: TapeDeckReflecting {
	func reflect_playback_mode() {
		reflect_playbackState_and_nowPlayingItem()
	}
	func reflect_now_playing_item() { 
		reflect_playbackState_and_nowPlayingItem()
	}
}
