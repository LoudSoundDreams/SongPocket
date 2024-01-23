//
//  MainToolbar.swift
//  LavaRock
//
//  Created by h on 2022-05-09.
//

import UIKit
import MusicKit
import MediaPlayer

// As of iOS 15.4 developer beta 4, if no responder between the VoiceOver-focused element and the app delegate implements `accessibilityPerformMagicTap`, then VoiceOver toggles audio playback. https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/SupportingAccessibility.html
@MainActor
final class MainToolbar {
	static let shared = MainToolbar()
	var barButtonItems: [UIBarButtonItem] {
		return [
			overflowButton, .flexibleSpace(),
			jumpBackButton, .flexibleSpace(),
			playPauseButton, .flexibleSpace(),
			jumpForwardButton, .flexibleSpace(),
		]
	}
	
	// MARK: - PRIVATE
	
	private static var player: SystemMusicPlayer? { .sharedIfAuthorized }
	
	private lazy var overflowButton = UIBarButtonItem(
		title: LRString.more,
		menu: Self.newOverflowMenu()
	)
	
	private lazy var playPauseButton = UIBarButtonItem()
	
	private lazy var jumpBackButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			title: LRString.skipBack15Seconds,
			image: UIImage(systemName: "gobackward.15"),
			primaryAction: UIAction { _ in
				Self.player?.playbackTime -= 15
			})
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	private lazy var jumpForwardButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			title: LRString.skipForward15Seconds,
			image: UIImage(systemName: "goforward.15"),
			primaryAction: UIAction { _ in
				Self.player?.playbackTime += 15
			})
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	
	// MARK: - Overflow menu
	
	private static func newOverflowMenu() -> UIMenu {
		let menuElements: [UIMenuElement] = [
			UIMenu(
				options: .displayInline,
				children: [
					UIDeferredMenuElement.uncached({ useMenuElements in
						let action = UIAction(
							title: LRString.repeat_,
							image: UIImage(systemName: "repeat.1"),
							attributes: {
								if Self.player == nil { return .disabled }
								return []
							}(),
							state: {
								guard let player = MPMusicPlayerController.systemMusicPlayerIfAuthorized else { return .off }
								return (player.repeatMode == .one) ? .on : .off
							}()
						) { _ in
							guard let player = Self.player else { return }
							if player.state.repeatMode == .one {
								player.state.repeatMode = MusicPlayer.RepeatMode.none
							} else {
								player.state.repeatMode = .one
							}
						}
						useMenuElements([action])
					}),
				]
			),
			
			UIMenu(
				options: .displayInline,
				preferredElementSize: .small,
				children: [
					
					UIDeferredMenuElement.uncached({ useMenuElements in
						let action = UIAction(
							title: LRString.previous,
							image: UIImage(systemName: "backward.end"),
							attributes: (Self.player == nil) ? .disabled : []
						) { _ in
							Task {
								try await Self.player?.skipToPreviousEntry()
							}
						}
						useMenuElements([action])
					}),
					
					UIDeferredMenuElement.uncached({ useMenuElements in
						let action = UIAction(
							title: LRString.restart,
							image: UIImage(systemName: "arrow.counterclockwise"),
							// I want to disable this when the playhead is already at start of track, but can’t reliably check that.
							attributes: (Self.player == nil) ? .disabled : []
						) { _ in
							Self.player?.restartCurrentEntry()
						}
						useMenuElements([action])
					}),
					
					UIDeferredMenuElement.uncached({ useMenuElements in
						let action = UIAction(
							title: LRString.next,
							image: UIImage(systemName: "forward.end"),
							attributes: (Self.player == nil) ? .disabled : []
						) { _ in
							Task {
								try await Self.player?.skipToNextEntry()
							}
						}
						useMenuElements([action])
					}),
					
				]
			),
			
		]
		return UIMenu(children: menuElements)
	}
	
	// MARK: -
	
	private init() {
		freshen()
		TapeDeck.shared.addReflector(weakly: self)
	}
	
	private func freshen() {
#if targetEnvironment(simulator)
		defer {
			showPause()
		}
#endif
		
		overflowButton.image = newOverflowButtonImage()
		
		guard
			let player = MPMusicPlayerController.systemMusicPlayerIfAuthorized
				// Ideally, also do this when no songs are in the player
		else {
			showPlay()
			
			// Disable everything
			barButtonItems.forEach {
				$0.isEnabled = false
				$0.accessibilityTraits.formUnion(.notEnabled) // As of iOS 15.3 developer beta 1, setting `isEnabled` doesn’t do this automatically.
			}
			overflowButton.isEnabled = true
			overflowButton.accessibilityTraits.subtract(.notEnabled)
			
			return
		}
		
		// Enable everything
		barButtonItems.forEach {
			$0.isEnabled = true
			$0.accessibilityTraits.subtract(.notEnabled)
		}
		
		if player.playbackState == .playing {
			showPause()
		} else {
			showPlay()
		}
	}
	private var hasRefreshenedOverflowButton = false
	private func newOverflowButtonImage() -> UIImage {
		let repeatOff = UIImage(systemName: "ellipsis.circle")!
		
		guard let player = MPMusicPlayerController.systemMusicPlayerIfAuthorized else {
			return repeatOff
		}
		switch player.repeatMode {
				// TO DO: Add accessibility labels or values when Repeat is on. What does the Photos app do with its overflow button when filtering to Shared Library?
			case .one: return UIImage(systemName: "ellipsis.circle.fill")!
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
				return repeatOff
		}
	}
	private func showPlay() {
		playPauseButton.title = LRString.play
		playPauseButton.primaryAction = UIAction(
			image: UIImage(systemName: "play.circle")
		) { _ in
			Task {
				try await Self.player?.play()
			}
		}
		playPauseButton.accessibilityTraits.formUnion(.startsMediaSession)
	}
	private func showPause() {
		playPauseButton.title = LRString.pause
		playPauseButton.primaryAction = UIAction(
			image: UIImage(systemName: "pause.circle")
		) { _ in
			Self.player?.pause()
		}
		playPauseButton.accessibilityTraits.subtract(.startsMediaSession)
	}
}
extension MainToolbar: TapeDeckReflecting {
	func reflect_playbackState() {
		freshen()
	}
	func reflect_nowPlaying() { 
		freshen()
	}
}
