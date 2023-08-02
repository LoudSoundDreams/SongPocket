//
//  MainToolbar__UIKit.swift
//  LavaRock
//
//  Created by h on 2022-05-09.
//

import UIKit
import MediaPlayer

// Instantiators might want to…
// • Implement `accessibilityPerformMagicTap` and toggle playback.
// However, as of iOS 15.4 developer beta 4, if no responder between the VoiceOver-focused element and the app delegate implements `accessibilityPerformMagicTap`, then VoiceOver toggles audio playback. https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/SupportingAccessibility.html
@MainActor
final class MainToolbar__UIKit {
	private static var player: MPMusicPlayerController? { TapeDeck.shared.player }
	
	// MARK: - Buttons
	
	var barButtonItems: [UIBarButtonItem] {
		return [
			overflowButton,
			.flexibleSpace(),
			jumpBackButton,
			.flexibleSpace(),
			playPauseButton,
			.flexibleSpace(),
			jumpForwardButton,
			.flexibleSpace(),
			nextButton,
		]
	}
	
	private lazy var overflowButton = UIBarButtonItem(
		title: LRString.more,
		image: Self.overflowButtonDefaultImage,
		menu: createOverflowMenu()
	)
	private lazy var jumpBackButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			title: LRString.skipBack10Seconds,
			image: UIImage(systemName: "gobackward.15"),
			primaryAction: UIAction { _ in
				Self.player?.currentPlaybackTime -= 15
			})
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	private lazy var playPauseButton = UIBarButtonItem()
	private lazy var jumpForwardButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			title: LRString.skipForward10Seconds,
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
			image: UIImage(systemName: "forward.end.circle"),
			primaryAction: UIAction { _ in
				Self.player?.skipToNextItem()
			})
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	
	// MARK: - Overflow menu
	
	private weak var settings_presenter: UIViewController? = nil
	private func createOverflowMenu() -> UIMenu {
		let menuElements: [UIMenuElement] = [
			UIAction(
				title: LRString.settings,
				image: UIImage(systemName: "gear")
			) { [weak self] _ in
				let toPresent: UIViewController = {
					let settingsTVC = UIStoryboard(name: "SettingsTVC", bundle: nil)
						.instantiateInitialViewController()!
					return UINavigationController(rootViewController: settingsTVC)
				}()
				toPresent.modalPresentationStyle = .formSheet
				self?.settings_presenter?.present(toPresent, animated: true)
			},
			createRepeatMenu(),
			createTransportMenu(),
		].reversed()
		return UIMenu(children: menuElements)
		
		func createRepeatMenu() -> UIMenu {
			return UIMenu(
				options: .displayInline,
				preferredElementSize: .small,
				children: [
					UIDeferredMenuElement.uncached({ useMenuElements in
						let action = UIAction(
							title: LRString.repeatOff,
							image: UIImage(systemName: "minus"),
							attributes: {
								if (Self.player == nil)
									|| (Self.player?.repeatMode == MPMusicRepeatMode.none)
								{
									// When this mode is selected, we want to show it as such, not disable it.
									// However, as of iOS 16.2 developer beta 1, when using `UIMenu.ElementSize.small`, neither `UIMenu.Options.singleSelection` nor `UIMenuElement.State.on` visually selects any menu item.
									// Disabling the selected mode is a compromise.
									return .disabled
								}
								return []
							}(),
							state: {
								guard let player = Self.player else {
									return .on // Default when disabled
								}
								return (player.repeatMode == MPMusicRepeatMode.none)
								? .on
								: .off
							}()
						) { _ in
							Self.player?.repeatMode = .none
						}
						useMenuElements([action])
					}),
					UIDeferredMenuElement.uncached({ useMenuElements in
						let action = UIAction(
							title: LRString.repeatAll,
							image: UIImage(systemName: "repeat"),
							attributes: {
								if (Self.player == nil)
									|| (Self.player?.repeatMode == .all)
								{
									return .disabled
								}
								return []
							}(),
							state: {
								guard let player = Self.player else {
									return .off
								}
								return (player.repeatMode == .all)
								? .on
								: .off
							}()
						) { action in
							Self.player?.repeatMode = .all
						}
						useMenuElements([action])
					}),
					UIDeferredMenuElement.uncached({ useMenuElements in
						let action = UIAction(
							title: LRString.repeat1,
							image: UIImage(systemName: "repeat.1"),
							attributes: {
								if (Self.player == nil)
									|| (Self.player?.repeatMode == .one)
								{
									return .disabled
								}
								return []
							}(),
							state: {
								guard let player = Self.player else {
									return .off
								}
								return (
									player.repeatMode == .one
									? .on
									: .off
								)
							}()
						) { _ in
							Self.player?.repeatMode = .one
						}
						useMenuElements([action])
					}),
				]
			)
		}
		
		func createTransportMenu() -> UIMenu {
			return UIMenu(
				options: .displayInline,
				children: [
					UIDeferredMenuElement.uncached({ useMenuElements in
						let action = UIAction(
							title: LRString.restart,
							image: UIImage(systemName: "arrow.counterclockwise.circle"),
							attributes: {
								// TO DO: Disable when playhead is already at start of track
								if Self.player == nil {
									return .disabled
								}
								return []
							}()
						) { _ in
							Self.player?.skipToBeginning()
						}
						useMenuElements([action])
					}),
					UIDeferredMenuElement.uncached({ useMenuElements in
						let action = UIAction(
							title: LRString.previous,
							image: UIImage(systemName: "backward.end.circle"),
							attributes: {
								var result: UIMenuElement.Attributes = [
									.keepsMenuPresented,
								]
								if Self.player == nil {
									result.formUnion(.disabled)
								}
								return result
							}()
						) { _ in
							Self.player?.skipToPreviousItem()
						}
						useMenuElements([action])
					}),
				]
			)
		}
	}
	
	// MARK: -
	
	init(
		weakly_Settings_presenter: UIViewController
	) {
		self.settings_presenter = weakly_Settings_presenter
		
		freshen()
		TapeDeck.shared.addReflector(weakly: self)
	}
	
	private static let overflowButtonDefaultImage = UIImage(systemName: "ellipsis.circle")!
	private var hasRefreshenedOverflowButton = false
	private func freshen() {
		freshenOverflowButton()
		
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
			let player = Self.player
				// Ideally, disable transport buttons when no songs are in the player
		else {
			configurePlayButton()
			
			// Enable or disable each button as appropriate
			barButtonItems.forEach {
				$0.isEnabled = false
				$0.accessibilityTraits.formUnion(.notEnabled) // As of iOS 15.3 developer beta 1, setting `isEnabled` doesn’t do this automatically.
			}
			overflowButton.isEnabled = true
			overflowButton.accessibilityTraits.subtract(.notEnabled)
			return
		}
		
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
		barButtonItems.forEach {
			$0.isEnabled = true
			$0.accessibilityTraits.subtract(.notEnabled)
		}
	}
	private func freshenOverflowButton() {
		overflowButton.image = { () -> UIImage in
			guard let player = Self.player else {
				return Self.overflowButtonDefaultImage
			}
			switch player.repeatMode {
					// TO DO: Add accessibility labels or values for “repeat all” and “repeat one”. What does the Photos app do with its overflow button when filtering to Shared Library?
				case .one:
					return UIImage(systemName: "repeat.1.circle.fill")!
				case .all:
					return UIImage(systemName: "repeat.circle.fill")!
				case
						.default,
						.none
					:
					// As of iOS 16.2 developer beta 3, when the user first grants access to Music, Media Player can incorrectly return `.none` for 8ms or longer.
					// That happens even if the app crashes while the permission alert is visible, and we get first access on next launch.
					if !hasRefreshenedOverflowButton {
						hasRefreshenedOverflowButton = true
						
						Task {
							try? await Task.sleep(for: .milliseconds(50))
							
							freshenOverflowButton()
						}
					}
					return Self.overflowButtonDefaultImage
				@unknown default:
					return Self.overflowButtonDefaultImage
			}
		}()
	}
}
extension MainToolbar__UIKit: TapeDeckReflecting {
	func reflect_playback_mode() {
		freshen()
	}
	
	func reflect_now_playing_item() {
		freshen()
	}
}
