// 2022-05-09

import UIKit
@preconcurrency import MusicKit
import MediaPlayer

// As of iOS 15.4 developer beta 4, if no responder between the VoiceOver-focused element and the app delegate implements `accessibilityPerformMagicTap`, then VoiceOver toggles audio playback. https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/SupportingAccessibility.html
@MainActor final class __MainToolbar {
	static let shared = __MainToolbar()
	lazy var barButtonItems: [UIBarButtonItem] = [
		.flexibleSpace(),
		playPauseButton, .flexibleSpace(),
		overflowButton,
	]
	var navigator: Weak<UINavigationController>? = nil
	
	private lazy var playPauseButton = UIBarButtonItem()
	private lazy var overflowButton = UIBarButtonItem(title: LRString.more, menu: UIMenu(children: [
		// We want to indicate which mode is active by selecting it, not disabling it.
		// However, as of iOS 17.4 developer beta 1, when using `UIMenu.ElementSize.small`, neither `UIMenu.Options.singleSelection` nor `UIMenuElement.State.on` visually selects any menu item.
		// Disabling the selected mode is a compromise.
		UIMenu(options: .displayInline, preferredElementSize: .small, children: [
			UIDeferredMenuElement.uncached { useMenuElements in
				let action = UIAction(title: LRString.skipBack15Seconds, image: UIImage(systemName: "gobackward.15"), attributes: (SystemMusicPlayer._shared == nil) ? [.disabled, .keepsMenuPresented] : [.keepsMenuPresented]) { _ in SystemMusicPlayer._shared?.playbackTime -= 15 }
				useMenuElements([action])
			},
			UIDeferredMenuElement.uncached { useMenuElements in
				let action = UIAction(title: LRString.skipForward15Seconds, image: UIImage(systemName: "goforward.15"), attributes: (SystemMusicPlayer._shared == nil) ? [.disabled, .keepsMenuPresented] : [.keepsMenuPresented]) { _ in SystemMusicPlayer._shared?.playbackTime += 15 }
				useMenuElements([action])
			},
		]),
		UIMenu(options: .displayInline, preferredElementSize: .small, children: [
			UIDeferredMenuElement.uncached { useMenuElements in
				// Ideally, disable this when there are no previous tracks to skip to.
				let action = UIAction(title: LRString.previous, image: UIImage(systemName: "backward.end"), attributes: (SystemMusicPlayer._shared == nil) ? .disabled : []) { _ in
					Task {
						try await SystemMusicPlayer._shared?.skipToPreviousEntry()
					}
				}
				useMenuElements([action])
			},
			UIDeferredMenuElement.uncached { useMenuElements in
				// I want to disable this when the playhead is already at start of track, but can’t reliably check that.
				let action = UIAction(title: LRString.restart, image: UIImage(systemName: "arrow.counterclockwise"), attributes: (SystemMusicPlayer._shared == nil) ? .disabled : []) { _ in SystemMusicPlayer._shared?.restartCurrentEntry() }
				useMenuElements([action])
			},
			UIDeferredMenuElement.uncached { useMenuElements in
				let action = UIAction(title: LRString.next, image: UIImage(systemName: "forward.end"), attributes: (SystemMusicPlayer._shared == nil) ? .disabled : []) { _ in
					Task {
						try await SystemMusicPlayer._shared?.skipToNextEntry()
					}
				}
				useMenuElements([action])
			},
		]),
		UIMenu(options: .displayInline, preferredElementSize: .small, children: [
			UIDeferredMenuElement.uncached { useMenuElements in
				let action = UIAction(
					title: LRString.repeatOff, image: UIImage(systemName: "minus"),
					attributes: {
						guard let __player = MPMusicPlayerController._system else { return .disabled }
						return (__player.repeatMode == MPMusicRepeatMode.none) ? .disabled : []
					}(),
					state: {
						guard let __player = MPMusicPlayerController._system else {
							// Assume Repeat is off
							return .on
						}
						return (__player.repeatMode == MPMusicRepeatMode.none) ? .on : .off
					}()
				) { _ in MPMusicPlayerController._system?.repeatMode = MPMusicRepeatMode.none }
				useMenuElements([action])
			},
			UIDeferredMenuElement.uncached { useMenuElements in
				let action = UIAction(
					title: LRString.repeat1, image: UIImage(systemName: "repeat.1"),
					attributes: {
						guard let __player = MPMusicPlayerController._system else { return .disabled }
						return (__player.repeatMode == .one) ? .disabled : []
					}(),
					state: {
						guard let __player = MPMusicPlayerController._system else { return .off }
						return (__player.repeatMode == .one) ? .on : .off
					}()
				) { _ in MPMusicPlayerController._system?.repeatMode = .one }
				useMenuElements([action])
			},
		]),
		UIDeferredMenuElement.uncached { useMenuElements in
			let action = UIAction(
				title: LRString.goToAlbum, image: UIImage(systemName: "square.stack"),
				attributes: {
					guard 
						SystemMusicPlayer._shared != nil,
						let albumInPlayer = Database.viewContext.songInPlayer()?.container
					else { return .disabled }
					return []
				}()
			) { [weak self] _ in
				guard
					let albumInPlayer = Database.viewContext.songInPlayer()?.container,
					let navigator = self?.navigator?.referencee
				else { return }
				navigator.popToRootViewController(animated: true)
				// TO DO: Scroll to album
				navigator.pushViewController({
					let songsTVC = UIStoryboard(name: "SongsTVC", bundle: nil).instantiateInitialViewController() as! SongsTVC
					songsTVC.viewModel = SongsViewModel(album: albumInPlayer)
					return songsTVC
				}(), animated: true)
			}
			useMenuElements([action])
		},
	]))
	
	private init() {
		refresh()
		AudioPlayer.shared.reflectorToolbar = Weak(self)
	}
	
	func refresh() {
#if targetEnvironment(simulator)
		defer { showPause() }
#endif
		
		overflowButton.image = newOverflowButtonImage()
		
		guard let __player = MPMusicPlayerController._system else {
			// Ideally, also do this when no songs are in the player
			
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
		
		guard let __player = MPMusicPlayerController._system else { return repeatOff }
		switch __player.repeatMode {
				// TO DO: Add accessibility labels or values when Repeat is on. What does the Photos app do with its overflow button when filtering to Shared Library?
			case .one: return UIImage(systemName: "repeat.1.circle.fill")!
			case .all, .none, .default: break
			@unknown default: break
		}
		// As of iOS 16.2 developer beta 3, when the user first grants access to Music, Media Player can incorrectly return `.none` for 8ms or longer.
		// That happens even if the app crashes while the permission alert is visible, and we get first access on next launch.
		if !hasRefreshedOverflowButton {
			hasRefreshedOverflowButton = true
			Task {
				try? await Task.sleep(for: .milliseconds(50))
				
				overflowButton.image = newOverflowButtonImage()
			}
		}
		return repeatOff
	}
	private var hasRefreshedOverflowButton = false
	private func showPlay() {
		playPauseButton.title = LRString.play
		playPauseButton.primaryAction = UIAction(image: UIImage(systemName: "play.circle")) { _ in
			Task {
				try await SystemMusicPlayer._shared?.play()
			}
		}
		playPauseButton.accessibilityTraits.formUnion(.startsMediaSession)
	}
	private func showPause() {
		playPauseButton.title = LRString.pause
		playPauseButton.primaryAction = UIAction(image: UIImage(systemName: "pause.circle")) { _ in SystemMusicPlayer._shared?.pause() }
		playPauseButton.accessibilityTraits.subtract(.startsMediaSession)
	}
}

// MARK: - SwiftUI

import SwiftUI

final class MainToolbarStatus: ObservableObject {
	static let shared = MainToolbarStatus()
	private init() {}
	@Published fileprivate(set) var inSelectMode = false
}

struct MainToolbar: View {
	@ObservedObject private var status: MainToolbarStatus = .shared
	var body: some View {
		Button {
			withAnimation {
				status.inSelectMode.toggle()
			}
		} label: { Image(systemName: status.inSelectMode ? "checkmark.circle.fill" : "checkmark.circle") }
		Spacer()
		if status.inSelectMode {
			Menu {
			} label: { Image(systemName: "arrow.up.arrow.down") }
			Spacer()
			Button {
			} label: { Image(systemName: "arrow.up.to.line") }
			Spacer()
			Button {
			} label: { Image(systemName: "arrow.down.to.line") }
		} else {
			Button {
			} label: { Image(systemName: "play.circle") }
			Spacer()
			Menu {
				ControlGroup {
					Button {
					} label: { Image(systemName: "gobackward.15") }
					Button {
					} label: { Image(systemName: "goforward.15") }
				}
				.menuActionDismissBehavior(.disabled)
				.controlGroupStyle(.compactMenu)
			} label: { Image(systemName: "ellipsis.circle") }
				.menuOrder(.fixed)
		}
	}
}
