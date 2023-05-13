//
//  MainToolbar.swift
//  LavaRock
//
//  Created by h on 2022-05-09.
//

import UIKit
import MediaPlayer
import SwiftUI

// Instantiators might want to …
// • Implement `accessibilityPerformMagicTap` and toggle playback.
// However, as of iOS 15.4 developer beta 4, if no responder between the VoiceOver-focused element and the app delegate implements `accessibilityPerformMagicTap`, then VoiceOver toggles audio playback. https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/SupportingAccessibility.html
@MainActor
final class MainToolbar {
	private static var player: MPMusicPlayerController? { TapeDeck.shared.player }
	
	private lazy var console_button = UIBarButtonItem(
		title: LRString.more,
		primaryAction: UIAction(
			handler: { [weak self] action in
				self?.console_presenter?.present(
					UIHostingController(
						rootView: ConsoleView()
					),
					animated: true
				)
			}
		)
	)
	private weak var console_presenter: UIViewController? = nil
	private let console_screen_host = UIHostingController(rootView: ConsoleView())
	
	private lazy var moreButton = UIBarButtonItem(
		title: LRString.more,
		image: Self.more_button_default_image,
		menu: create_menu_More()
	)
	private weak var settings_presenter: UIViewController? = nil
	
	private func create_menu_More() -> UIMenu {
		return UIMenu(
			presentsUpward: true,
			menuElementGroups: [
				[
					UIAction(
						title: LRString.appleMusic,
						image: UIImage(systemName: "arrow.up.forward.app"),
						handler: { action in
							UIApplication.shared.open(.music)
						}
					),
					
					UIAction(
						title: LRString.settings,
						image: UIImage(systemName: "gear"),
						handler: { [weak self] action in
							let toPresent: UIViewController = (
								Enabling.swiftUI__settings
								? UIHostingController(rootView: SettingsScreen__SwiftUI())
								: SettingsNC()
							)
							toPresent.modalPresentationStyle = .formSheet
							self?.settings_presenter?.present(toPresent, animated: true)
						}
					),
				],
				
				[
					create_submenu_Repeat(),
				],
				
				[
					create_submenu_Transport(),
				],
			]
		)
	}
	
	private func create_submenu_Repeat() -> UIMenu {
		return UIMenu(
			options: [
				.displayInline,
			],
			preferredElementSize: .small,
			children: [
				UIDeferredMenuElement.uncached({ useMenuElements in
					let action = UIAction(
						title: LRString.repeatOff,
						image: UIImage(systemName: "minus"),
						attributes: {
							var result: UIMenuElement.Attributes = []
							if (Self.player == nil)
								|| (Self.player?.repeatMode == MPMusicRepeatMode.none)
							{
								// When this mode is selected, we want to show it as such, not disable it.
								// However, as of iOS 16.2 developer beta 1, when using `UIMenu.ElementSize.small`, neither `UIMenu.Options.singleSelection` nor `UIMenuElement.State.on` visually selects any menu item.
								// Disabling the selected mode is a compromise.
								result.formUnion(.disabled)
							}
							return result
						}(),
						state: {
							guard let player = Self.player else {
								return .on // Default when disabled
							}
							return (
								player.repeatMode == MPMusicRepeatMode.none
								? .on
								: .off
							)
						}(),
						handler: { action in
							Self.player?.repeatMode = .none
						}
					)
					useMenuElements([action])
				}),
				
				UIDeferredMenuElement.uncached({ useMenuElements in
					let action = UIAction(
						title: LRString.repeatAll,
						image: UIImage(systemName: "repeat"),
						attributes: {
							var result: UIMenuElement.Attributes = []
							if (Self.player == nil)
								|| (Self.player?.repeatMode == .all)
							{
								result.formUnion(.disabled)
							}
							return result
						}(),
						state: {
							guard let player = Self.player else {
								return .off
							}
							return (
								player.repeatMode == .all
								? .on
								: .off
							)
						}(),
						handler: { action in
							Self.player?.repeatMode = .all
						}
					)
					useMenuElements([action])
				}),
				
				UIDeferredMenuElement.uncached({ useMenuElements in
					let action = UIAction(
						title: LRString.repeat1,
						image: UIImage(systemName: "repeat.1"),
						attributes: {
							var result: UIMenuElement.Attributes = []
							if (Self.player == nil)
								|| (Self.player?.repeatMode == .one)
							{
								result.formUnion(.disabled)
							}
							return result
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
						}(),
						handler: { action in
							Self.player?.repeatMode = .one
						}
					)
					useMenuElements([action])
				}),
			]
		)
	}
	
	private func create_submenu_Transport() -> UIMenu {
		return UIMenu(
			options: [
				.displayInline,
			],
			children: [
				UIDeferredMenuElement.uncached({ useMenuElements in
					let action = UIAction(
						title: LRString.restart,
						image: UIImage(systemName: "arrow.counterclockwise.circle"),
						attributes: {
							var result: UIMenuElement.Attributes = []
							// TO DO: Disable when playhead is already at start of track
							if Self.player == nil {
								result.formUnion(.disabled)
							}
							return result
						}(),
						handler: { action in
							Self.player?.skipToBeginning()
						}
					)
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
						}(),
						handler: { action in
							Self.player?.skipToPreviousItem()
						}
					)
					useMenuElements([action])
				}),
			]
		)
	}
	
	private lazy var skipBackButton: UIBarButtonItem = {
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
	
	private lazy var skipForwardButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			title: LRString.skipForward10Seconds,
			image: UIImage(systemName: "goforward.15"),
			primaryAction: UIAction { _ in
				Self.player?.currentPlaybackTime += 15
			})
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	
	private lazy var nextSongButton: UIBarButtonItem = {
		let button = UIBarButtonItem(
			title: LRString.next,
			image: UIImage(systemName: "forward.end.circle"),
			primaryAction: UIAction { _ in
				Self.player?.skipToNextItem()
			})
		button.accessibilityTraits.formUnion(.startsMediaSession)
		return button
	}()
	
	var buttons_array: [UIBarButtonItem] {
		if Enabling.inAppPlayer {
			return [
				console_button,
				.flexibleSpace(),
				skipBackButton,
				.flexibleSpace(),
				playPauseButton,
				.flexibleSpace(),
				skipForwardButton,
				.flexibleSpace(),
				nextSongButton,
			]
		} else {
			return [
				moreButton,
				.flexibleSpace(),
				skipBackButton,
				.flexibleSpace(),
				playPauseButton,
				.flexibleSpace(),
				skipForwardButton,
				.flexibleSpace(),
				nextSongButton,
			]
		}
	}
	
	init(
		weakly_Console_presenter: UIViewController,
		weakly_Settings_presenter: UIViewController
	) {
		self.console_presenter = weakly_Console_presenter
		self.settings_presenter = weakly_Settings_presenter
		
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
	
	private static let showConsoleButtonDefaultImage = UIImage(systemName: "list.bullet.circle")!
	private static let more_button_default_image = UIImage(systemName: "ellipsis.circle")!
	private var has_re_freshened_more_button = false
	private func freshen() {
		
		func freshen_more_button() {
			let new_image: UIImage
			defer {
				moreButton.image = new_image
			}
			guard let player = Self.player else {
				// Configure ellipsis icon
				new_image = Self.more_button_default_image
				return
			}
			new_image = {
				switch player.repeatMode {
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
						if !has_re_freshened_more_button {
							has_re_freshened_more_button = true
							
							Task {
								try await Task.sleep(nanoseconds: 0_050_000_000) // 50ms
								
								freshen_more_button()
							}
						}
						return Self.more_button_default_image
					@unknown default:
						return Self.more_button_default_image
				}
			}()
		}
		freshen_more_button()
		
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
			!(Enabling.inAppPlayer && Reel.mediaItems.isEmpty) // When enabling in-app player, when reel is empty, disable transport buttons.
		else {
			configurePlayButton()
			
			console_button.image = Self.showConsoleButtonDefaultImage
			
			// Enable or disable each button as appropriate
			buttons_array.forEach {
				$0.isEnabledSetToFalseAlongWithAccessibilityTrait()
			}
			moreButton.isEnabledSetToTrueAlongWithAccessibilityTrait()
			console_button.isEnabledSetToTrueAlongWithAccessibilityTrait()
			return
		}
		
		console_button.image = {
			switch player.repeatMode {
				case .one:
					return UIImage(systemName: "repeat.1.circle.fill")!
				case .all:
					return UIImage(systemName: "repeat.circle.fill")!
				case
						.default,
						.none
					:
					return Self.showConsoleButtonDefaultImage
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
			$0.isEnabledSetToTrueAlongWithAccessibilityTrait()
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
