// 2022-05-09

import UIKit
@preconcurrency import MusicKit
import MediaPlayer

// As of iOS 15.4 developer beta 4, if no responder between the VoiceOver-focused element and the app delegate implements `accessibilityPerformMagicTap`, then VoiceOver toggles audio playback. https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/SupportingAccessibility.html
@MainActor final class __MainToolbar {
	static let shared = __MainToolbar()
	lazy var barButtonItems: [UIBarButtonItem] = [.flexibleSpace(), playPauseButton, .flexibleSpace(), overflowButton]
	var albumsTVC: WeakRef<AlbumsTVC>? = nil
	
	private lazy var playPauseButton = UIBarButtonItem()
	private lazy var overflowButton = UIBarButtonItem(title: InterfaceText.more, menu: UIMenu(children: [
		// TO DO: Add hack to enable elements in Simulator when appropriate
		
		// We want to indicate which mode is active by selecting it, not disabling it.
		// However, as of iOS 17.4 developer beta 1, when using `UIMenu.ElementSize.small`, neither `UIMenu.Options.singleSelection` nor `UIMenuElement.State.on` visually selects any menu item.
		// Disabling the selected mode is a compromise.
		UIMenu(options: .displayInline, preferredElementSize: .small, children: [
			UIDeferredMenuElement.uncached { use in use([
				UIAction(title: InterfaceText.skipBack15Seconds, image: UIImage(systemName: "gobackward.15"), attributes: (SystemMusicPlayer._shared?.queue.currentEntry == nil) ? [.disabled, .keepsMenuPresented] : [.keepsMenuPresented]) { _ in SystemMusicPlayer._shared?.playbackTime -= 15 }
			])},
			UIDeferredMenuElement.uncached { use in use([
				UIAction(title: InterfaceText.skipForward15Seconds, image: UIImage(systemName: "goforward.15"), attributes: (SystemMusicPlayer._shared?.queue.currentEntry == nil) ? [.disabled, .keepsMenuPresented] : [.keepsMenuPresented]) { _ in SystemMusicPlayer._shared?.playbackTime += 15 }
			])},
		]),
		UIMenu(options: .displayInline, preferredElementSize: .small, children: [
			UIDeferredMenuElement.uncached { use in use([
				// Ideally, disable this when there are no previous tracks to skip to.
				UIAction(title: InterfaceText.previous, image: UIImage(systemName: "backward.end"), attributes: (SystemMusicPlayer._shared?.queue.currentEntry == nil) ? .disabled : []) { _ in
					Task { try await SystemMusicPlayer._shared?.skipToPreviousEntry() }
				}
			])},
			UIDeferredMenuElement.uncached { use in use([
				// I want to disable this when the playhead is already at start of track, but can’t reliably check that.
				UIAction(title: InterfaceText.restart, image: UIImage(systemName: "arrow.counterclockwise"), attributes: (SystemMusicPlayer._shared?.queue.currentEntry == nil) ? .disabled : []) { _ in SystemMusicPlayer._shared?.restartCurrentEntry() }
			])},
			UIDeferredMenuElement.uncached { use in use([
				UIAction(title: InterfaceText.next, image: UIImage(systemName: "forward.end"), attributes: (SystemMusicPlayer._shared?.queue.currentEntry == nil) ? .disabled : []) { _ in
					Task { try await SystemMusicPlayer._shared?.skipToNextEntry() }
				}
			])},
		]),
		UIMenu(options: .displayInline, preferredElementSize: .small, children: [
			UIDeferredMenuElement.uncached { use in use([
				UIAction(
					title: InterfaceText.repeatOff, image: UIImage(systemName: "minus"),
					attributes: {
						guard
							let __player = MPMusicPlayerController._system,
							SystemMusicPlayer._shared?.queue.currentEntry != nil
						else { return .disabled }
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
			])},
			UIDeferredMenuElement.uncached { use in use([
				UIAction(
					title: InterfaceText.repeat1, image: UIImage(systemName: "repeat.1"),
					attributes: {
						guard
							let __player = MPMusicPlayerController._system,
							SystemMusicPlayer._shared?.queue.currentEntry != nil
						else { return .disabled }
						return (__player.repeatMode == .one) ? .disabled : []
					}(),
					state: {
						guard let __player = MPMusicPlayerController._system else { return .off }
						return (__player.repeatMode == .one) ? .on : .off
					}()
				) { _ in MPMusicPlayerController._system?.repeatMode = .one }
			])},
		]),
		UIDeferredMenuElement.uncached { [weak self] use in use([
			UIAction(
				title: InterfaceText.nowPlaying, image: UIImage(systemName: WorkingOn.inlineTracklist ? "square.stack" : "chevron.forward"),
				attributes: {
					guard
						SystemMusicPlayer._shared?.queue.currentEntry != nil,
						let albumsTVC = self?.albumsTVC?.referencee, !albumsTVC.isBeneathCurrentAlbum
					else { return .disabled }
					return []
				}()
			) { [weak self] _ in self?.albumsTVC?.referencee?.goToCurrentAlbum() }
		])},
	]))
	
	private init() {
		refresh()
		AudioPlayer.shared.reflectorToolbar = WeakRef(self)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(databaseChanged), name: .LRMergedChanges, object: nil) // Because Media Player doesn’t post “now-playing item changed” notifications when entering or exiting the “Not Playing” state.
	}
	@objc private func databaseChanged() { refresh() }
	
	func refresh() {
#if targetEnvironment(simulator)
		defer {
			showPause()
			playPauseButton.isEnabled = true
		}
#endif
		
		overflowButton.image = newOverflowButtonImage()
		
		guard
			let __player = MPMusicPlayerController._system,
			SystemMusicPlayer._shared?.queue.currentEntry != nil
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
		let repeatOff = UIImage(systemName: "ellipsis.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor))!
		
		guard
			let __player = MPMusicPlayerController._system,
			SystemMusicPlayer._shared?.queue.currentEntry != nil
		else { return repeatOff }
		switch __player.repeatMode {
				// TO DO: Add accessibility labels or values when Repeat is on. What does the Photos app do with its overflow button when filtering to Shared Library?
			case .one: return UIImage(systemName: "repeat.1.circle.fill")!
			case .all, .none, .default: break
			@unknown default: break
		}
		return repeatOff
	}
	private func showPlay() {
		playPauseButton.title = InterfaceText.play
		playPauseButton.primaryAction = UIAction(image: UIImage(systemName: "play.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor))) { _ in
			Task { try await SystemMusicPlayer._shared?.play() }
		}
		playPauseButton.accessibilityTraits.formUnion(.startsMediaSession)
	}
	private func showPause() {
		playPauseButton.title = InterfaceText.pause
		playPauseButton.primaryAction = UIAction(image: UIImage(systemName: "pause.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor))) { _ in SystemMusicPlayer._shared?.pause() }
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
