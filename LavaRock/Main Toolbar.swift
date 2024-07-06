// 2022-05-09

@preconcurrency import UIKit
@preconcurrency import MusicKit
import MediaPlayer

// As of iOS 15.4 developer beta 4, if no responder between the VoiceOver-focused element and the app delegate implements `accessibilityPerformMagicTap`, then VoiceOver toggles audio playback. https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/SupportingAccessibility.html
@MainActor final class __MainToolbar {
	static let shared = __MainToolbar()
	var barButtonItems: [UIBarButtonItem] { [.flexibleSpace(), playPauseButton, .flexibleSpace(), overflowButton] }
	var albumsTVC: WeakRef<AlbumsTVC>? = nil
	func observeMediaPlayerController() {
		refresh()
		MPMusicPlayerController._system?.beginGeneratingPlaybackNotifications()
		NotificationCenter.default.addObserverOnce(self, selector: #selector(refresh), name: .MPMusicPlayerControllerPlaybackStateDidChange, object: nil)
		NotificationCenter.default.addObserverOnce(self, selector: #selector(refresh), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: nil)
	}
	
	private init() {
		refresh()
		NotificationCenter.default.addObserverOnce(self, selector: #selector(refresh), name: MusicRepo.mergedChanges, object: nil) // Because when Media Player enters or exits the “Not Playing” state, it doesn’t post “now-playing item changed” notifications.
	}
	
	private let playPauseButton = UIBarButtonItem()
	private let overflowButton = UIBarButtonItem()
	
	@objc private func refresh() {
		refreshPlayPause()
		refreshOverflow()
	}
	
	private func refreshPlayPause() {
#if targetEnvironment(simulator)
		showPause()
		playPauseButton.isEnabled = true
#else
		guard
			let __player = MPMusicPlayerController._system,
			nil != SystemMusicPlayer._shared?.queue.currentEntry
		else {
			showPlay()
			
			playPauseButton.isEnabled = false
			playPauseButton.accessibilityTraits.formUnion(.notEnabled) // As of iOS 15.3 developer beta 1, setting `isEnabled` doesn’t do this automatically.
			
			return
		}
		
		playPauseButton.isEnabled = true
		playPauseButton.accessibilityTraits.subtract(.notEnabled)
		
		if __player.playbackState == .playing {
			showPause()
		} else {
			showPlay()
		}
#endif
	}
	private func showPlay() {
		playPauseButton.title = InterfaceText.play
		playPauseButton.primaryAction = UIAction(image: UIImage(systemName: "play.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor))) { _ in Task { try await SystemMusicPlayer._shared?.play() } }
		playPauseButton.accessibilityTraits.formUnion(.startsMediaSession)
	}
	private func showPause() {
		playPauseButton.title = InterfaceText.pause
		playPauseButton.primaryAction = UIAction(image: UIImage(systemName: "pause.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor))) { _ in SystemMusicPlayer._shared?.pause() }
		playPauseButton.accessibilityTraits.subtract(.startsMediaSession)
	}
	
	private func refreshOverflow() {
		overflowButton.preferredMenuElementOrder = .fixed
		overflowButton.menu = newOverflowMenu()
		
		let newImage: UIImage
		let newLabel: String
		defer {
			overflowButton.image = newImage
			overflowButton.accessibilityLabel = newLabel
		}
		let regularImage = UIImage(systemName: "ellipsis.circle.fill", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tintColor))!
		let regularLabel = InterfaceText.more
		guard
			let __player = MPMusicPlayerController._system,
			nil != SystemMusicPlayer._shared?.queue.currentEntry
		else {
			newImage = regularImage
			newLabel = regularLabel
			return
		}
		newImage = {
			switch __player.repeatMode {
				case .one: return UIImage(systemName: "repeat.1.circle.fill")!
				case .all, .none, .default: break
				@unknown default: break
			}
			return regularImage
		}()
		newLabel = [InterfaceText.repeat1, regularLabel].formattedAsNarrowList()
	}
	private func newOverflowTitle() -> String {
		if
			MusicAuthorization.currentStatus == .authorized,
			Database.viewContext.fetchPlease(Collection.fetchRequest()).isEmpty
		{ return InterfaceText._emptyLibraryMessage }
		return ""
	}
	private func newOverflowMenu() -> UIMenu {
		return UIMenu(title: newOverflowTitle(), children: [
			UIDeferredMenuElement.uncached { [weak self] use in use([
				UIAction(title: InterfaceText.goToAlbum, image: UIImage(systemName: "square.stack"), attributes: {
#if targetEnvironment(simulator)
					return []
#else
					let albumsInDatabase = Database.viewContext.fetchPlease(Album.fetchRequest())
					guard
						let currentAlbumID = MPMusicPlayerController._system?.nowPlayingItem?.albumPersistentID,
						nil != albumsInDatabase.first(where: { album in
							currentAlbumID == album.albumPersistentID
						})
					else { return .disabled }
					return []
#endif
				}()) { [weak self] _ in self?.albumsTVC?.referencee?.showCurrent() }
			])},
			// We want to indicate which mode is active by selecting it, not disabling it.
			// However, as of iOS 17.4 developer beta 1, when using `UIMenu.ElementSize.small`, neither `UIMenu.Options.singleSelection` nor `UIMenuElement.State.on` visually selects any menu item.
			// Disabling the selected mode is a compromise.
			UIMenu(options: .displayInline, preferredElementSize: .small, children: [
				UIDeferredMenuElement.uncached { use in use([
					UIAction(
						title: InterfaceText.repeatOff, image: UIImage(systemName: "minus"),
						attributes: {
							guard
								let __player = MPMusicPlayerController._system,
								nil != SystemMusicPlayer._shared?.queue.currentEntry
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
#if targetEnvironment(simulator)
							return []
#else
							guard
								let __player = MPMusicPlayerController._system,
								nil != SystemMusicPlayer._shared?.queue.currentEntry
							else { return .disabled }
							return (__player.repeatMode == .one) ? .disabled : []
#endif
						}(),
						state: {
							guard let __player = MPMusicPlayerController._system else { return .off }
							return (__player.repeatMode == .one) ? .on : .off
						}()
					) { _ in MPMusicPlayerController._system?.repeatMode = .one }
				])},
			]),
			UIMenu(options: .displayInline, preferredElementSize: .small, children: [
				UIDeferredMenuElement.uncached { use in use([
					// Ideally, disable this when there are no previous tracks to skip to.
					UIAction(title: InterfaceText.previous, image: UIImage(systemName: "backward.end"), attributes: {
#if targetEnvironment(simulator)
						return []
#else
						return (SystemMusicPlayer._shared?.queue.currentEntry == nil) ? .disabled : []
#endif
					}()) { _ in Task { try await SystemMusicPlayer._shared?.skipToPreviousEntry() } }
				])},
				UIDeferredMenuElement.uncached { use in use([
					// I want to disable this when the playhead is already at start of track, but can’t reliably check that.
					UIAction(title: InterfaceText.restart, image: UIImage(systemName: "arrow.counterclockwise"), attributes: {
#if targetEnvironment(simulator)
						return []
#else
						return (SystemMusicPlayer._shared?.queue.currentEntry == nil) ? .disabled : []
#endif
					}()) { _ in SystemMusicPlayer._shared?.restartCurrentEntry() }
				])},
				UIDeferredMenuElement.uncached { use in use([
					UIAction(title: InterfaceText.next, image: UIImage(systemName: "forward.end"), attributes: {
#if targetEnvironment(simulator)
						return []
#else
						return (SystemMusicPlayer._shared?.queue.currentEntry == nil) ? .disabled : []
#endif
					}()) { _ in Task { try await SystemMusicPlayer._shared?.skipToNextEntry() } }
				])},
			]),
			UIMenu(options: .displayInline, preferredElementSize: .small, children: [
				UIDeferredMenuElement.uncached { use in use([
					UIAction(title: InterfaceText.skipBack15Seconds, image: UIImage(systemName: "gobackward.15"), attributes: {
#if targetEnvironment(simulator)
						return [.keepsMenuPresented]
#else
						return (SystemMusicPlayer._shared?.queue.currentEntry == nil) ? [.disabled, .keepsMenuPresented] : [.keepsMenuPresented]
#endif
					}()) { _ in SystemMusicPlayer._shared?.playbackTime -= 15 }
				])},
				UIDeferredMenuElement.uncached { use in use([
					UIAction(title: InterfaceText.skipForward15Seconds, image: UIImage(systemName: "goforward.15"), attributes: {
#if targetEnvironment(simulator)
						return [.keepsMenuPresented]
#else
						return (SystemMusicPlayer._shared?.queue.currentEntry == nil) ? [.disabled, .keepsMenuPresented] : [.keepsMenuPresented]
#endif
					}()) { _ in SystemMusicPlayer._shared?.playbackTime += 15 }
				])},
			]),
		])
	}
}

// MARK: - SwiftUI

import SwiftUI

struct MainToolbar: View {
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
	@ObservedObject private var status: MainToolbarStatus = .shared
}

@MainActor final class MainToolbarStatus: ObservableObject {
	static let shared = MainToolbarStatus()
	private init() {}
	@Published fileprivate(set) var inSelectMode = false
}
