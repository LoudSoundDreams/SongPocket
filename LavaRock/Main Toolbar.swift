// 2022-05-09

import UIKit
@preconcurrency import MusicKit
import MediaPlayer

// As of iOS 15.4 developer beta 4, if no responder between the VoiceOver-focused element and the app delegate implements `accessibilityPerformMagicTap`, then VoiceOver toggles audio playback. https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/SupportingAccessibility.html
@MainActor final class MainToolbar {
	static let shared = MainToolbar()
	lazy var barButtonItems: [UIBarButtonItem] = [
		.flexibleSpace(),
		jumpBackButton, .flexibleSpace(),
		playPauseButton, .flexibleSpace(),
		jumpForwardButton, .flexibleSpace(),
		overflowButton,
	]
	
	private lazy var playPauseButton = UIBarButtonItem()
	private lazy var jumpBackButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			title: LRString.skipBack15Seconds,
			image: UIImage(systemName: "gobackward.15"),
			primaryAction: UIAction { _ in
				SystemMusicPlayer._shared?.playbackTime -= 15
			})
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	private lazy var jumpForwardButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			title: LRString.skipForward15Seconds,
			image: UIImage(systemName: "goforward.15"),
			primaryAction: UIAction { _ in
				SystemMusicPlayer._shared?.playbackTime += 15
			})
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	private lazy var overflowButton = UIBarButtonItem(
		title: LRString.more,
		menu: {
			let menuElements: [UIMenuElement] = [
				// We want to indicate which mode is active by selecting it, not disabling it.
				// However, as of iOS 17.4 developer beta 1, when using `UIMenu.ElementSize.small`, neither `UIMenu.Options.singleSelection` nor `UIMenuElement.State.on` visually selects any menu item.
				// Disabling the selected mode is a compromise.
				UIMenu(
					options: .displayInline,
					preferredElementSize: .small,
					children: [
						UIDeferredMenuElement.uncached({ useMenuElements in
							let action = UIAction(
								title: LRString.repeatOff,
								image: UIImage(systemName: "minus"),
								attributes: {
									guard let __player = MPMusicPlayerController._system else {
										return .disabled
									}
									if __player.repeatMode == MPMusicRepeatMode.none {
										return .disabled
									} else {
										return []
									}
								}(),
								state: {
									guard let __player = MPMusicPlayerController._system else {
										// Assume Repeat is off
										return .on
									}
									return (__player.repeatMode == MPMusicRepeatMode.none) ? .on : .off
								}()
							) { _ in
								MPMusicPlayerController._system?.repeatMode = MPMusicRepeatMode.none
							}
							useMenuElements([action])
						}),
						UIDeferredMenuElement.uncached({ useMenuElements in
							let action = UIAction(
								title: LRString.repeat1,
								image: UIImage(systemName: "repeat.1"),
								attributes: {
									// Disable if appropriate
									guard let __player = MPMusicPlayerController._system else {
										return .disabled
									}
									if __player.repeatMode == .one {
										return .disabled
									} else {
										return []
									}
								}(),
								state: {
									// Select if appropriate
									guard let __player = MPMusicPlayerController._system else { return .off }
									return (__player.repeatMode == .one) ? .on : .off
								}()
							) { _ in
								MPMusicPlayerController._system?.repeatMode = .one
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
								// Ideally, disable this when there are no previous tracks to skip to.
								attributes: (SystemMusicPlayer._shared == nil) ? .disabled : []
							) { _ in
								Task {
									try await SystemMusicPlayer._shared?.skipToPreviousEntry()
								}
							}
							useMenuElements([action])
						}),
						UIDeferredMenuElement.uncached({ useMenuElements in
							let action = UIAction(
								title: LRString.restart,
								image: UIImage(systemName: "arrow.counterclockwise"),
								// I want to disable this when the playhead is already at start of track, but can’t reliably check that.
								attributes: (SystemMusicPlayer._shared == nil) ? .disabled : []
							) { _ in
								SystemMusicPlayer._shared?.restartCurrentEntry()
							}
							useMenuElements([action])
						}),
						UIDeferredMenuElement.uncached({ useMenuElements in
							let action = UIAction(
								title: LRString.next,
								image: UIImage(systemName: "forward.end"),
								attributes: (SystemMusicPlayer._shared == nil) ? .disabled : []
							) { _ in
								Task {
									try await SystemMusicPlayer._shared?.skipToNextEntry()
								}
							}
							useMenuElements([action])
						}),
					]
				),
			]
			return UIMenu(children: menuElements)
		}()
	)
	
	private init() {
		freshen()
		
		TapeDeck.shared.reflectorToolbar = Weak(self)
	}
	
	private func freshen() {
#if targetEnvironment(simulator)
		defer {
			showPause()
		}
#endif
		
		overflowButton.image = newOverflowButtonImage()
		
		guard
			let __player = MPMusicPlayerController._system
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
		
		if __player.playbackState == .playing {
			showPause()
		} else {
			showPlay()
		}
	}
	private func newOverflowButtonImage() -> UIImage {
		let repeatOff = UIImage(systemName: "ellipsis.circle")!
		
		guard let __player = MPMusicPlayerController._system else {
			return repeatOff
		}
		switch __player.repeatMode {
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
				return repeatOff
		}
	}
	private var hasRefreshenedOverflowButton = false
	private func showPlay() {
		playPauseButton.title = LRString.play
		playPauseButton.primaryAction = UIAction(
			image: UIImage(systemName: "play.circle")
		) { _ in
			Task {
				try await SystemMusicPlayer._shared?.play()
			}
		}
		playPauseButton.accessibilityTraits.formUnion(.startsMediaSession)
	}
	private func showPause() {
		playPauseButton.title = LRString.pause
		playPauseButton.primaryAction = UIAction(
			image: UIImage(systemName: "pause.circle")
		) { _ in
			SystemMusicPlayer._shared?.pause()
		}
		playPauseButton.accessibilityTraits.subtract(.startsMediaSession)
	}
}
extension MainToolbar: TapeDeckReflecting {
	func reflect_playbackState() { freshen() }
	func reflect_nowPlaying() { freshen() }
}

// MARK: - SwiftUI

import SwiftUI

struct MainToolbar_Previews: PreviewProvider {
	static var previews: some View {
		Color.clear.mainToolbar()
	}
}
extension View {
	func mainToolbar() -> some View {
		toolbar {
			ToolbarItem(placement: .bottomBar) { selectButton }
			ToolbarItem(placement: .bottomBar) { Spacer() }
			ToolbarItem(placement: .bottomBar) { jumpBackButton }
			ToolbarItem(placement: .bottomBar) { Spacer() }
			ToolbarItem(placement: .bottomBar) { playPauseButton }
			ToolbarItem(placement: .bottomBar) { Spacer() }
			ToolbarItem(placement: .bottomBar) { jumpForwardButton }
			ToolbarItem(placement: .bottomBar) { Spacer() }
			ToolbarItem(placement: .bottomBar) { overflowButton }
		}
	}
	
	private var selectButton: some View {
		Button {
		} label: {
			Image(systemName: "checkmark.circle")
		}
	}
	private var jumpBackButton: some View {
		Button {
		} label: {
			Image(systemName: "gobackward.15")
		}
	}
	private var playPauseButton: some View {
		Button {
		} label: {
			Image(systemName: "play.circle")
		}
	}
	private var jumpForwardButton: some View {
		Button {
		} label: {
			Image(systemName: "goforward.15")
		}
	}
	private var overflowButton: some View {
		Menu {
		} label: {
			Image(systemName: "ellipsis.circle")
		}
	}
}
