//
//  CanPresentOpenMusicAlert.swift
//  LavaRock
//
//  Created by h on 2022-07-06.
//

import UIKit

protocol CanPresentOpenMusicAlert: UIViewController {
	func presentOpenMusicAlertIfNeeded(
		willPlayNextAsOpposedToLast: Bool,
		havingVerbedSongCount songCount: Int,
		firstSongTitle: String)
}

extension SongsTVC: CanPresentOpenMusicAlert {
	func presentOpenMusicAlertIfNeeded(
		willPlayNextAsOpposedToLast: Bool,
		havingVerbedSongCount songCount: Int,
		firstSongTitle: String
	) {
		if Enabling.console {
			return
		}
		
		let defaults = UserDefaults.standard
		let defaultsKey = LRUserDefaultsKey.shouldExplainQueueAction.rawValue
		
		defaults.register(defaults: [defaultsKey: true])
		guard defaults.bool(forKey: defaultsKey) else { return }
		
		let dontShowAgainAction = UIAlertAction(
			title: LocalizedString.dontShowAgain,
			style: .default
		) { _ in
			self.willPlayLaterAlertIsPresented = false
			defaults.set(
				false,
				forKey: defaultsKey)
		}
		let openMusicAction = UIAlertAction(
			title: LocalizedString.openMusic,
			style: .default
		) { _ in
			UIApplication.shared.open(.music)
		}
		let okAction = UIAlertAction(
			title: LocalizedString.ok,
			style: .default
		) { _ in
			self.willPlayLaterAlertIsPresented = false
		}
		
		let alert = UIAlertController(
			title: {
				let prefix = (
					willPlayNextAsOpposedToLast
					? LocalizedString.prefix_playingNext
					: LocalizedString.prefix_playingLast
				)
				let content: String = {
					if songCount == 1 {
						// No “and more song(s)” required.
						return String.localizedStringWithFormat(
							LocalizedString.format_quoted,
							firstSongTitle)
					} else {
						// “and more song(s)” required.
						return String.localizedStringWithFormat(
							LocalizedString.format_title_songTitleAndXMoreSongs,
							firstSongTitle,
							songCount - 1)
					}
				}()
				return "\(prefix)\(content)"
			}(),
			message: {
				return LocalizedString.sentence_openMusicToEditTheQueue
			}(),
			preferredStyle: .alert)
		alert.addAction(dontShowAgainAction)
		alert.addAction(openMusicAction)
		alert.addAction(okAction)
		alert.preferredAction = okAction
		willPlayLaterAlertIsPresented = true
		present(alert, animated: true)
	}
}
