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
		if Enabling.inAppPlayer || true {
			return
		}
		
		let defaults = UserDefaults.standard
		let defaultsKey = LRUserDefaultsKey.shouldExplainQueueAction.rawValue
		
		defaults.register(defaults: [defaultsKey: true])
		guard defaults.bool(forKey: defaultsKey) else { return }
		
		let dontShowAgainAction = UIAlertAction(
			title: LRString.dontShowAgain,
			style: .default
		) { _ in
			self.willPlayLaterAlertIsPresented = false
			defaults.set(
				false,
				forKey: defaultsKey)
		}
		let openMusicAction = UIAlertAction(
			title: LRString.openMusic,
			style: .default
		) { _ in
			UIApplication.shared.open(.music)
		}
		let okAction = UIAlertAction(
			title: LRString.ok,
			style: .default
		) { _ in
			self.willPlayLaterAlertIsPresented = false
		}
		
		let alert = UIAlertController(
			title: {
				let prefix = (
					willPlayNextAsOpposedToLast
					? LRString.prefix_playingNext
					: LRString.prefix_playingLast
				)
				let content: String = {
					if songCount == 1 {
						// No “and more song(s)” required.
						return String.localizedStringWithFormat(
							LRString.format_quoted,
							firstSongTitle)
					} else {
						// “and more song(s)” required.
						return String.localizedStringWithFormat(
							LRString.format_title_songTitleAndXMoreSongs,
							firstSongTitle,
							songCount - 1)
					}
				}()
				return "\(prefix)\(content)"
			}(),
			message: {
				return LRString.sentence_openMusicToEditTheQueue
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
